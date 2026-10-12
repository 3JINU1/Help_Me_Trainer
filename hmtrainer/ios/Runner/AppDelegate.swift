import Flutter
import ActivityKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static let liveActivityChannelName = "com.example.hmtrainer/workout_activity"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: Self.liveActivityChannelName,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "UNAVAILABLE", message: "App delegate is unavailable.", details: nil))
        return
      }
      switch call.method {
      case "sync":
        guard let state = call.arguments as? [String: Any] else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Workout state is missing.", details: nil))
          return
        }
        self.syncWorkoutActivity(state: state, result: result)
      case "end":
        self.endWorkoutActivity(result: result)
      case "consumeRecordRequest":
        self.consumeRecordRequest(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func syncWorkoutActivity(
    state values: [String: Any],
    result: @escaping FlutterResult
  ) {
    guard
      let exerciseName = values["exerciseName"] as? String,
      let currentSet = values["currentSet"] as? Int,
      let totalSets = values["totalSets"] as? Int,
      let canRecord = values["canRecord"] as? Bool
    else {
      result(FlutterError(code: "INVALID_ARGUMENT", message: "Workout state is invalid.", details: nil))
      return
    }
    let restStartedAt = (values["restStartedAtEpochMs"] as? Double).map {
      Date(timeIntervalSince1970: $0 / 1000)
    }

    if #available(iOS 16.1, *) {
      guard ActivityAuthorizationInfo().areActivitiesEnabled else {
        result(false)
        return
      }
      let state = WorkoutActivityAttributes.ContentState(
        exerciseName: exerciseName,
        currentSet: currentSet,
        totalSets: totalSets,
        canRecord: canRecord,
        restStartedAt: restStartedAt,
        pendingRecordRequestID: nil
      )
      Task {
        do {
          if let activity = Activity<WorkoutActivityAttributes>.activities.first {
            await activity.update(using: state)
          } else {
            _ = try Activity.request(
              attributes: WorkoutActivityAttributes(sessionID: UUID().uuidString),
              contentState: state,
              pushType: nil
            )
          }
          result(true)
        } catch {
          result(FlutterError(code: "ACTIVITY_ERROR", message: error.localizedDescription, details: nil))
        }
      }
    } else {
      result(false)
    }
  }

  private func endWorkoutActivity(result: @escaping FlutterResult) {
    if #available(iOS 16.1, *) {
      Task {
        for activity in Activity<WorkoutActivityAttributes>.activities {
          await activity.end(using: nil, dismissalPolicy: .immediate)
        }
        result(nil)
      }
    } else {
      result(nil)
    }
  }

  private func consumeRecordRequest(result: @escaping FlutterResult) {
    guard #available(iOS 16.1, *) else {
      result(nil)
      return
    }
    guard let activity = Activity<WorkoutActivityAttributes>.activities.first,
          activity.contentState.pendingRecordRequestID != nil else {
      result(nil)
      return
    }
    var state = activity.contentState
    state.pendingRecordRequestID = nil
    let request = [
      "exerciseName": activity.contentState.exerciseName,
      "setIndex": activity.contentState.currentSet - 1,
    ] as [String: Any]
    Task {
      await activity.update(using: state)
      result(request)
    }
  }
}

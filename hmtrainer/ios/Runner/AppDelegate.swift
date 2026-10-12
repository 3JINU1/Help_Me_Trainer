import Flutter
import ActivityKit
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static let liveActivityChannelName = "com.example.hmtrainer/workout_activity"
  private static let restNotificationIdentifierPrefix = "workout-rest-alert-"

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
      case "startRestTimer":
        guard let arguments = call.arguments as? [String: Any] else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Rest timer settings are missing.", details: nil))
          return
        }
        self.startRestTimer(arguments: arguments, result: result)
      case "stopRestTimer":
        self.stopRestTimer(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    UNUserNotificationCenter.current().delegate = self
    WorkoutIntentBridge.handler = { info in
      await MainActor.run {
        channel.invokeMethod("recordTap", arguments: info)
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
    let currentReps = values["currentReps"] as? Int
    let targetReps = values["targetReps"] as? Int ?? 0
    let restMaxSeconds = values["restMaxSeconds"] as? Int ?? 0
    let weightLabel = values["weightLabel"] as? String ?? ""
    let showRestInButton = values["showRestInButton"] as? Bool ?? false
    let restStartedAt = (values["restStartedAtEpochMs"] as? Double).map {
      Date(timeIntervalSince1970: $0 / 1000)
    }

    if #available(iOS 16.2, *), WorkoutTapCoordinator.pendingFinalize {
      result(true)
      return
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
        currentReps: currentReps,
        targetReps: targetReps,
        weightLabel: weightLabel,
        restMaxSeconds: restMaxSeconds,
        showRestInButton: showRestInButton,
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
    if WorkoutIntentBridge.queuedTaps.isEmpty {
      result(nil)
    } else {
      result(WorkoutIntentBridge.queuedTaps.removeFirst())
    }
  }

  private func startRestTimer(
    arguments: [String: Any],
    result: @escaping FlutterResult
  ) {
    guard
      let startedAtEpochMs = arguments["startedAtEpochMs"] as? Double,
      let alertSeconds = arguments["alertSeconds"] as? [Int]
    else {
      result(FlutterError(code: "INVALID_ARGUMENT", message: "Rest timer settings are invalid.", details: nil))
      return
    }

    let center = UNUserNotificationCenter.current()
    Task {
      do {
        await removeRestNotifications(from: center)
        let settings = await center.notificationSettings()
        let allowed: Bool
        if settings.authorizationStatus == .notDetermined {
          allowed = try await center.requestAuthorization(options: [.alert, .sound])
        } else {
          allowed = settings.authorizationStatus == .authorized ||
            settings.authorizationStatus == .provisional
        }
        guard allowed else {
          result(false)
          return
        }

        let startedAt = Date(timeIntervalSince1970: startedAtEpochMs / 1000)
        for (index, elapsedSeconds) in alertSeconds.enumerated() where elapsedSeconds > 0 {
          let fireDate = startedAt.addingTimeInterval(TimeInterval(elapsedSeconds))
          let remaining = fireDate.timeIntervalSinceNow
          guard remaining > 0 else { continue }

          let content = UNMutableNotificationContent()
          content.title = "휴식 타이머"
          content.body = "\(elapsedSeconds)초 휴식 시간이 지났습니다."
          content.sound = .default
          let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(remaining, 1),
            repeats: false
          )
          let request = UNNotificationRequest(
            identifier: Self.restNotificationIdentifierPrefix + String(index),
            content: content,
            trigger: trigger
          )
          try await center.add(request)
        }
        result(true)
      } catch {
        result(FlutterError(code: "REST_NOTIFICATION_ERROR", message: error.localizedDescription, details: nil))
      }
    }
  }

  private func stopRestTimer(result: @escaping FlutterResult) {
    Task {
      await removeRestNotifications(from: .current())
      result(true)
    }
  }

  private func removeRestNotifications(from center: UNUserNotificationCenter) async {
    let pendingIdentifiers = await withCheckedContinuation {
      (continuation: CheckedContinuation<[String], Never>) in
      center.getPendingNotificationRequests { requests in
        continuation.resume(
          returning: requests
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.restNotificationIdentifierPrefix) }
        )
      }
    }
    center.removePendingNotificationRequests(withIdentifiers: pendingIdentifiers)

    let deliveredIdentifiers = await withCheckedContinuation {
      (continuation: CheckedContinuation<[String], Never>) in
      center.getDeliveredNotifications { notifications in
        continuation.resume(
          returning: notifications
            .map(\.request.identifier)
            .filter { $0.hasPrefix(Self.restNotificationIdentifierPrefix) }
        )
      }
    }
    center.removeDeliveredNotifications(withIdentifiers: deliveredIdentifiers)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if notification.request.identifier.hasPrefix(Self.restNotificationIdentifierPrefix) {
      completionHandler([])
    } else if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound])
    } else {
      completionHandler([.alert, .sound])
    }
  }
}

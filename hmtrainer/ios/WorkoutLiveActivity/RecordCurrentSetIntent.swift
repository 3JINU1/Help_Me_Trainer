import ActivityKit
import AppIntents
import Foundation

enum WorkoutIntentBridge {
  // Set by the app process so taps can reach Flutter directly.
  static var handler: (([String: Any]) async -> Void)?
  // Taps received while Flutter was not reachable.
  static var queuedTaps: [[String: Any]] = []
}

@available(iOS 16.2, *)
enum WorkoutTapCoordinator {
  static var pendingFinalize = false
  private static var token = 0
  private static var restEndTask: Task<Void, Never>?

  // Applies a tap to the Live Activity immediately so the island responds without a Flutter round trip.
  @MainActor
  static func handleTap() async -> [String: Any]? {
    guard let activity = Activity<WorkoutActivityAttributes>.activities.first else {
      return nil
    }
    var state = activity.contentState
    guard state.canRecord else { return nil }
    var info: [String: Any] = [
      "exerciseName": state.exerciseName,
      "setIndex": state.currentSet - 1,
    ]

    if state.showRestInButton {
      restEndTask?.cancel()
      state.showRestInButton = false
      info["endRest"] = true
      await activity.update(using: state)
      return info
    }

    state.currentReps = state.currentReps.map { max($0 - 1, 0) } ?? state.targetReps
    token += 1
    let myToken = token
    pendingFinalize = true
    await activity.update(using: state)

    DispatchQueue.global().async {
      ProcessInfo.processInfo.performExpiringActivity(withReason: "workout-set") { expired in
        if !expired { Thread.sleep(forTimeInterval: 1.5) }
      }
      Task { @MainActor in await finalize(token: myToken) }
    }
    return info
  }

  @MainActor
  private static func finalize(token myToken: Int) async {
    guard myToken == token,
          let activity = Activity<WorkoutActivityAttributes>.activities.first
    else { return }
    var state = activity.contentState
    pendingFinalize = false
    guard state.currentReps != nil else { return }
    let startedAt = Date()
    state.currentReps = nil
    state.restStartedAt = startedAt
    if state.currentSet < state.totalSets {
      state.currentSet += 1
      state.showRestInButton = true
    } else {
      state.canRecord = false
    }
    await activity.update(using: state)

    restEndTask?.cancel()
    let maxSeconds = state.restMaxSeconds
    guard state.showRestInButton, maxSeconds > 0 else { return }
    restEndTask = Task { @MainActor in
      try? await Task.sleep(nanoseconds: UInt64(maxSeconds) * 1_000_000_000)
      guard !Task.isCancelled,
            let current = Activity<WorkoutActivityAttributes>.activities.first,
            current.contentState.restStartedAt == startedAt
      else { return }
      var ended = current.contentState
      ended.showRestInButton = false
      await current.update(using: ended)
    }
  }
}

@available(iOS 17.0, *)
struct RecordCurrentSetIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "현재 세트 기록"
  static var openAppWhenRun = false

  @Parameter(title: "운동 세션")
  var sessionID: String

  init() {}

  init(sessionID: String) {
    self.sessionID = sessionID
  }

  func perform() async throws -> some IntentResult {
    guard let info = await WorkoutTapCoordinator.handleTap() else {
      return .result()
    }
    if let handler = WorkoutIntentBridge.handler {
      await handler(info)
    } else {
      WorkoutIntentBridge.queuedTaps.append(info)
    }
    return .result()
  }
}

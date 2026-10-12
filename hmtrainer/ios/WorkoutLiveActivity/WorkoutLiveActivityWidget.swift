import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

@main
struct WorkoutLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Label("운동 진행 중", systemImage: "figure.strengthtraining.traditional")
            .font(.headline)
          Spacer()
          setLabel(context.state)
        }
        Text(context.state.exerciseName)
          .font(.title3.weight(.semibold))
          .lineLimit(1)
        restLabel(context.state)
        recordButton(context.state, sessionID: context.attributes.sessionID)
      }
      .padding()
      .activityBackgroundTint(.black)
      .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Image(systemName: "figure.strengthtraining.traditional")
        }
        DynamicIslandExpandedRegion(.center) {
          VStack(alignment: .leading, spacing: 2) {
            Text(context.state.exerciseName).lineLimit(1)
            setLabel(context.state)
          }
        }
        DynamicIslandExpandedRegion(.trailing) {
          restLabel(context.state)
        }
        DynamicIslandExpandedRegion(.bottom) {
          recordButton(context.state, sessionID: context.attributes.sessionID)
        }
      } compactLeading: {
        Image(systemName: "figure.strengthtraining.traditional")
      } compactTrailing: {
        Text("\(context.state.currentSet)/\(context.state.totalSets)")
      } minimal: {
        Image(systemName: "figure.strengthtraining.traditional")
      }
      .keylineTint(.red)
    }
  }

  @ViewBuilder
  private func recordButton(
    _ state: WorkoutActivityAttributes.ContentState,
    sessionID: String
  ) -> some View {
    if state.canRecord {
      if #available(iOS 17.0, *) {
        Button(
          intent: RecordCurrentSetIntent(
            sessionID: sessionID
          )
        ) {
          Label("현재 세트 기록", systemImage: "checkmark.circle.fill")
            .font(.subheadline.weight(.semibold))
        }
        .tint(.red)
      } else {
        Text("세트 기록은 iOS 17 이상에서 지원")
          .font(.caption)
      }
    }
  }

  private func setLabel(_ state: WorkoutActivityAttributes.ContentState) -> some View {
    Text("\(state.currentSet) / \(state.totalSets)세트")
      .font(.subheadline.weight(.medium))
  }

  @ViewBuilder
  private func restLabel(_ state: WorkoutActivityAttributes.ContentState) -> some View {
    if let restStartedAt = state.restStartedAt {
      HStack(spacing: 4) {
        Image(systemName: "timer")
        Text(timerInterval: restStartedAt...Date.distantFuture, countsDown: false)
          .monospacedDigit()
      }
      .font(.caption)
      .foregroundStyle(.secondary)
    } else {
      Text("휴식 대기")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
}

struct RecordCurrentSetIntent: AppIntent {
  static var title: LocalizedStringResource = "현재 세트 기록"
  static var openAppWhenRun = true

  @Parameter(title: "운동 세션")
  var sessionID: String

  init() {}

  init(sessionID: String) {
    self.sessionID = sessionID
  }

  func perform() async throws -> some IntentResult {
    guard
      let activity = Activity<WorkoutActivityAttributes>.activities.first(where: {
        $0.attributes.sessionID == sessionID
      }),
      activity.contentState.canRecord
    else {
      return .result()
    }
    var state = activity.contentState
    state.pendingRecordRequestID = UUID().uuidString
    await activity.update(using: state)
    return .result()
  }
}

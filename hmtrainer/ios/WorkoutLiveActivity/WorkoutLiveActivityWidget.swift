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
          Image(systemName: "figure.strengthtraining.traditional")
          Spacer()
          setLabel(context.state)
        }
        workoutRow(context.state, sessionID: context.attributes.sessionID)
      }
      .padding()
      .activityBackgroundTint(.black)
      .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Image(systemName: "figure.strengthtraining.traditional")
        }
        DynamicIslandExpandedRegion(.trailing) {
          setLabel(context.state)
            .padding(.trailing, 10)
        }
        DynamicIslandExpandedRegion(.bottom) {
          workoutRow(context.state, sessionID: context.attributes.sessionID)
          .padding(.horizontal, 10)
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

  private func workoutRow(
    _ state: WorkoutActivityAttributes.ContentState,
    sessionID: String
  ) -> some View {
    HStack(spacing: 12) {
      RoundedRectangle(cornerRadius: 10)
        .fill(Color.white.opacity(0.15))
        .frame(width: 48, height: 48)
        .overlay(Image(systemName: "dumbbell.fill").foregroundStyle(.white))
      VStack(alignment: .leading, spacing: 2) {
        Text(state.exerciseName)
          .font(.headline)
          .lineLimit(1)
        Text(state.weightLabel)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      Spacer(minLength: 0)
      recordButton(state, sessionID: sessionID)
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
          recordButtonLabel(state)
        }
        .buttonStyle(.plain)
      } else {
        Text("세트 기록은 iOS 17 이상에서 지원")
          .font(.caption)
      }
    }
  }

  private func recordButtonLabel(
    _ state: WorkoutActivityAttributes.ContentState
  ) -> some View {
    let resting = state.showRestInButton && state.restStartedAt != nil
    let filled = resting || state.currentReps != nil
    return ZStack {
      Capsule()
        .strokeBorder(Color.red, lineWidth: 2)
        .background(Capsule().fill(filled ? Color.red : Color.clear))
      if resting, let start = state.restStartedAt {
        Text(
          timerInterval: start...start.addingTimeInterval(
            Double(max(state.restMaxSeconds, 60)) + 1
          ),
          pauseTime: nil,
          countsDown: false,
          showsHours: false
        )
        .monospacedDigit()
        .multilineTextAlignment(.center)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.white)
        .frame(width: 64)
      } else if let reps = state.currentReps {
        Text("\(reps)")
          .font(.title3.weight(.bold))
          .foregroundStyle(.white)
      }
    }
    .frame(width: resting ? 84 : 44, height: 44)
    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: resting)
    .animation(.easeOut(duration: 0.15), value: state.currentReps)
  }

  private func setLabel(_ state: WorkoutActivityAttributes.ContentState) -> some View {
    Text("\(state.currentSet)/\(state.totalSets)")
      .font(.subheadline.weight(.medium))
  }

  @ViewBuilder
  private func restLabel(_ state: WorkoutActivityAttributes.ContentState) -> some View {
    if state.showRestInButton {
      EmptyView()
    } else if let restStartedAt = state.restStartedAt {
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

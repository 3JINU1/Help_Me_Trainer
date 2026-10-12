import ActivityKit
import Foundation

struct WorkoutActivityAttributes: ActivityAttributes {
  let sessionID: String

  struct ContentState: Codable, Hashable {
    var exerciseName: String
    var currentSet: Int
    var totalSets: Int
    var canRecord: Bool
    var restStartedAt: Date?
    var pendingRecordRequestID: String?
  }
}

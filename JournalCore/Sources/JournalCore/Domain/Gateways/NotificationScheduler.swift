import Foundation

/// Pulls the user back in once a pending entry's follow-up questions are ready —
/// capture can happen offline, but the Debrief agent's questions need Claude, so
/// this is how "later, when you're online" actually reaches the user. Narrow by
/// design: this isn't a general notifications API, just the one thing the app
/// needs to schedule.
public protocol NotificationScheduler: Sendable {
    func requestAuthorization() async -> Bool
    func scheduleFollowUpNotification(entryID: UUID, questionCount: Int) async throws

    /// Called once the user actually answers (or skips) an entry's follow-ups, so
    /// a reminder that already did its job doesn't fire anyway.
    func cancelFollowUpNotification(entryID: UUID)
}

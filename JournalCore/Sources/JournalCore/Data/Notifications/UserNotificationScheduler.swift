import Foundation
import UserNotifications

/// `NotificationScheduler` backed by `UNUserNotificationCenter`.
public struct UserNotificationScheduler: NotificationScheduler {
    /// Key under which the entry id is stored in a delivered notification's
    /// `userInfo`, so the app can deep-link to that entry's follow-up questions.
    public static let entryIDKey = "entryID"

    public init() {}

    public func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    public func scheduleFollowUpNotification(entryID: UUID, questionCount: Int) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Your journal has a question"
        content.body = questionCount == 1
            ? "One quick question about your last session."
            : "\(questionCount) quick questions about your last session."
        content.userInfo = [Self.entryIDKey: entryID.uuidString]
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: entryID.uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )

        try await UNUserNotificationCenter.current().add(request)
    }

    public func cancelFollowUpNotification(entryID: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [entryID.uuidString])
    }
}

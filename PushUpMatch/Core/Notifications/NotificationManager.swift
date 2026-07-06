import UserNotifications

/// Local notification scheduling for daily training reminders.
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private let reminderID = "daily_training_reminder"

    private init() {}

    /// Asks for permission. Returns true when granted.
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Schedules the repeating daily reminder (default 19:00 local time).
    func scheduleDailyReminder(hour: Int = 19) {
        let content = UNMutableNotificationContent()
        content.title = "⚽ Match time!"
        content.body = "Your country needs you — a quick push-up match keeps your streak alive."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: reminderID, content: content, trigger: trigger)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminderID])
        center.add(request)
    }

    func cancelDailyReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [reminderID])
    }
}

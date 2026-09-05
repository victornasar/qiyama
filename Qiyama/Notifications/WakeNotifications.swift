import Foundation
import UserNotifications

enum WakeNotifications {
    static func ensureSetup() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        default:
            return false
        }
    }

    static func cancel(_ id: String?) async {
        guard let id else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    static func schedule(for day: DayOutcome) async -> String? {
        let granted = await ensureSetup()
        guard granted else { return nil }
        await cancel(day.notificationId)

        guard let wakeAt = ISO8601DateFormatter.qiyamaDate(from: day.wakeAtISO) else { return nil }
        if wakeAt.timeIntervalSinceNow <= 5 { return nil }

        let content = UNMutableNotificationContent()
        content.title = "Qiyama"
        content.body = day.assistanceLevel >= 1
            ? "Forest is rising. Open and walk to your mark."
            : "Forest is rising. Get up."
        content.sound = .default
        content.userInfo = ["type": "wake", "dateKey": day.dateKey]

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: wakeAt
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let id = UUID().uuidString
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        do {
            try await UNUserNotificationCenter.current().add(request)
            return id
        } catch {
            return nil
        }
    }
}

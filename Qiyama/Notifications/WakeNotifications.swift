import Foundation
import UserNotifications

enum WakeNotifications {
    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    static func isAuthorized() async -> Bool {
        switch await authorizationStatus() {
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false
        }
    }

    static func isDenied() async -> Bool {
        await authorizationStatus() == .denied
    }

    /// Explicit opt-in only (permission toggle). Never call from schedule/bootstrap.
    static func requestAuthorization() async -> Bool {
        switch await authorizationStatus() {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            do {
                return try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound, .badge])
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
        // Optional — never prompt here. Guideline 4.5.4: notifications must not be required.
        guard await isAuthorized() else { return nil }
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

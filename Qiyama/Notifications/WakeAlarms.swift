import AlarmKit
import AppIntents
import Foundation

/// The authoritative wake signal. Fires from a locked or force-quit phone through the
/// system alert channel — the one path on iOS actually immune to the media volume slider,
/// which a plain UNUserNotificationCenter local notification cannot do either (delivery
/// there only shows a banner; it never runs app code unless the user taps it). Everything
/// in WakeAudioController — the forest ramp, the hardware-volume pin — is a supplemental
/// layer riding on top of this, not a substitute for it: an app's own AVAudioPlayer output
/// can always be silenced by the volume buttons once the screen locks, with no public API
/// to stop that. See spikes/AlarmKitSpike/FINDINGS.md.
enum WakeAlarms {
    struct Metadata: AlarmMetadata {
        let dateKey: String
    }

    static func ensureAuthorized() async -> Bool {
        let manager = AlarmManager.shared
        switch manager.authorizationState {
        case .authorized:
            return true
        case .notDetermined:
            return (try? await manager.requestAuthorization()) == .authorized
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    static func cancel(_ id: String?) {
        guard let id, let uuid = UUID(uuidString: id) else { return }
        try? AlarmManager.shared.cancel(id: uuid)
    }

    /// Silence an alarm that may currently be alerting (in-app dismiss — QR scan, "already
    /// prayed", etc.) — separate from `cancel`, which only removes a not-yet-fired schedule.
    static func silence(_ id: String?) {
        guard let id, let uuid = UUID(uuidString: id) else { return }
        try? AlarmManager.shared.stop(id: uuid)
        try? AlarmManager.shared.cancel(id: uuid)
    }

    static func schedule(for day: DayOutcome) async -> String? {
        guard let wakeAt = ISO8601DateFormatter.qiyamaDate(from: day.wakeAtISO) else { return nil }
        guard wakeAt.timeIntervalSinceNow > 5 else { return nil }
        return await scheduleAlarm(at: wakeAt, dateKey: day.dateKey, previousId: day.alarmId)
    }

    /// Practice — the exact same AlarmKit pipeline as the overnight wake, just fired a few
    /// seconds out, so locking the screen and killing the volume during a practice run
    /// actually exercises the mechanism that's supposed to survive that, not just the
    /// supplemental forest ambience. Forest audio still plays alongside it, unchanged.
    static func scheduleTest(dateKey: String, secondsFromNow: TimeInterval, previousId: String? = nil) async -> String? {
        let fireDate = Date().addingTimeInterval(secondsFromNow)
        return await scheduleAlarm(at: fireDate, dateKey: dateKey, previousId: previousId)
    }

    private static func scheduleAlarm(at wakeAt: Date, dateKey: String, previousId: String?) async -> String? {
        let authorized = await ensureAuthorized()
        guard authorized else { return nil }
        cancel(previousId)

        let id = UUID()
        let alert = AlarmPresentation.Alert(
            title: "Qiyama",
            // stopButton is unused by the system as of iOS 26.1 (the alert always shows its
            // own default Stop) but the initializer still requires one on 26.0.
            stopButton: AlarmButton(text: "Stop", textColor: .white, systemImageName: "stop.fill"),
            secondaryButton: AlarmButton(text: "I'm up", textColor: .white, systemImageName: "figure.walk"),
            secondaryButtonBehavior: .custom
        )
        let attributes = AlarmAttributes(
            presentation: AlarmPresentation(alert: alert),
            metadata: Metadata(dateKey: dateKey),
            tintColor: .green
        )
        let configuration = AlarmManager.AlarmConfiguration<Metadata>.alarm(
            schedule: .fixed(wakeAt),
            attributes: attributes,
            stopIntent: WakeAlarmStopIntent(alarmIDString: id.uuidString),
            secondaryIntent: WakeAlarmOpenIntent(),
            sound: .default
        )

        do {
            _ = try await AlarmManager.shared.schedule(id: id, configuration: configuration)
            return id.uuidString
        } catch {
            return nil
        }
    }
}

/// System Stop just needs to silence the alarm — it does not need to open the app.
/// "Got me out of bed" still needs the QR scan; the app's own wake-window check picks that
/// up the next time it's foregrounded, same as if the user had ignored a plain notification.
struct WakeAlarmStopIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop"

    @Parameter(title: "Alarm ID")
    var alarmIDString: String

    init() {
        alarmIDString = ""
    }

    init(alarmIDString: String) {
        self.alarmIDString = alarmIDString
    }

    func perform() async throws -> some IntentResult {
        if let id = UUID(uuidString: alarmIDString) {
            try? AlarmManager.shared.stop(id: id)
        }
        return .result()
    }
}

/// "I'm up" — foregrounds Qiyama so the forest ramp + QR scan continue immediately.
/// Foregrounding alone is enough: AppStore re-checks the wake window every time the app
/// becomes active (see QiyamaApp's scenePhase handling) and activates from there.
struct WakeAlarmOpenIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Open Qiyama"
    static var supportedModes: IntentModes { .foreground(.immediate) }

    init() {}

    func perform() async throws -> some IntentResult {
        .result()
    }
}

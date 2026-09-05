import AlarmKit
import Foundation
import SwiftUI

@MainActor
@Observable
final class AlarmService {
    private(set) var authorizationState: AlarmManager.AuthorizationState
    private(set) var alarms: [Alarm] = []
    private(set) var logLines: [String] = []
    private(set) var lastError: String?

    private let manager = AlarmManager.shared

    init() {
        authorizationState = manager.authorizationState
        refreshAlarms()
        log("Boot. auth=\(describe(authorizationState))")
    }

    func refresh() {
        authorizationState = manager.authorizationState
        refreshAlarms()
    }

    func requestAuthorization() async {
        do {
            let state = try await manager.requestAuthorization()
            authorizationState = state
            lastError = nil
            log("requestAuthorization → \(describe(state))")
        } catch {
            lastError = String(describing: error)
            log("requestAuthorization FAILED: \(error)")
        }
        refreshAlarms()
    }

    /// Countdown timer — fires after `seconds` even if we don't have a wall-clock schedule.
    func scheduleTimer(seconds: TimeInterval) async {
        let id = UUID()
        do {
            let attributes = makeAttributes(title: "Spike timer (\(Int(seconds))s)")
            let configuration: AlarmManager.AlarmConfiguration<SpikeMetadata> = .timer(
                duration: seconds,
                attributes: attributes,
                sound: .default
            )
            let alarm = try await manager.schedule(id: id, configuration: configuration)
            lastError = nil
            log("Scheduled TIMER id=\(id.uuidString.prefix(8)) in \(Int(seconds))s state=\(alarm.state)")
        } catch {
            lastError = String(describing: error)
            log("schedule TIMER FAILED: \(error)")
        }
        refreshAlarms()
    }

    /// Fixed absolute date — primary test for overnight / killed-app wake.
    func scheduleFixed(secondsFromNow: TimeInterval) async {
        let id = UUID()
        let fireDate = Date().addingTimeInterval(secondsFromNow)
        do {
            let attributes = makeAttributes(title: "Spike fixed")
            let configuration = AlarmManager.AlarmConfiguration<SpikeMetadata>(
                schedule: .fixed(fireDate),
                attributes: attributes,
                sound: .default
            )
            let alarm = try await manager.schedule(id: id, configuration: configuration)
            lastError = nil
            let fmt = fireDate.formatted(date: .omitted, time: .standard)
            log("Scheduled FIXED id=\(id.uuidString.prefix(8)) at \(fmt) state=\(alarm.state)")
        } catch {
            lastError = String(describing: error)
            log("schedule FIXED FAILED: \(error)")
        }
        refreshAlarms()
    }

    /// Relative clock time (today/tomorrow), no weekly recurrence.
    func scheduleRelative(minutesFromNow: Int) async {
        let id = UUID()
        let calendar = Calendar.current
        guard let fire = calendar.date(byAdding: .minute, value: minutesFromNow, to: Date()) else {
            log("Could not compute relative fire date")
            return
        }
        let hour = calendar.component(.hour, from: fire)
        let minute = calendar.component(.minute, from: fire)
        do {
            let time = Alarm.Schedule.Relative.Time(hour: hour, minute: minute)
            let schedule = Alarm.Schedule.relative(.init(time: time, repeats: .never))
            let attributes = makeAttributes(title: "Spike relative \(hour):\(String(format: "%02d", minute))")
            let configuration: AlarmManager.AlarmConfiguration<SpikeMetadata> = .alarm(
                schedule: schedule,
                attributes: attributes,
                sound: .default
            )
            let alarm = try await manager.schedule(id: id, configuration: configuration)
            lastError = nil
            log("Scheduled RELATIVE id=\(id.uuidString.prefix(8)) \(hour):\(String(format: "%02d", minute)) state=\(alarm.state)")
        } catch {
            lastError = String(describing: error)
            log("schedule RELATIVE FAILED: \(error)")
        }
        refreshAlarms()
    }

    func cancelAll() {
        do {
            let existing = try manager.alarms
            for alarm in existing {
                try manager.cancel(id: alarm.id)
            }
            lastError = nil
            log("Cancelled \(existing.count) alarm(s)")
        } catch {
            lastError = String(describing: error)
            log("cancelAll FAILED: \(error)")
        }
        refreshAlarms()
    }

    func clearLog() {
        logLines = []
    }

    // MARK: - Private

    private func makeAttributes(title: String) -> AlarmAttributes<SpikeMetadata> {
        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: title),
            stopButton: AlarmButton(
                text: "Stop",
                textColor: .white,
                systemImageName: "stop.circle"
            )
        )
        return AlarmAttributes(
            presentation: AlarmPresentation(alert: alert),
            metadata: SpikeMetadata(label: title),
            tintColor: Color(red: 0.18, green: 0.62, blue: 0.42)
        )
    }

    private func refreshAlarms() {
        do {
            alarms = try manager.alarms
        } catch {
            alarms = []
            log("alarms getter FAILED: \(error)")
        }
    }

    private func log(_ message: String) {
        let stamp = Date().formatted(date: .omitted, time: .standard)
        logLines.insert("[\(stamp)] \(message)", at: 0)
        if logLines.count > 80 {
            logLines = Array(logLines.prefix(80))
        }
    }

    private func describe(_ state: AlarmManager.AuthorizationState) -> String {
        switch state {
        case .notDetermined: return "notDetermined"
        case .denied: return "denied"
        case .authorized: return "authorized"
        @unknown default: return "unknown"
        }
    }
}

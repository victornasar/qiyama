import AlarmKit
import SwiftUI

struct ContentView: View {
    @State private var service = AlarmService()

    var body: some View {
        NavigationStack {
            List {
                Section("Authorization") {
                    LabeledContent("State", value: authLabel)
                    Button("Request authorization") {
                        Task { await service.requestAuthorization() }
                    }
                    Button("Refresh") {
                        service.refresh()
                    }
                }

                Section("Schedule (device tests)") {
                    Button("Timer in 45s") {
                        Task { await service.scheduleTimer(seconds: 45) }
                    }
                    Button("Fixed date in 90s") {
                        Task { await service.scheduleFixed(secondsFromNow: 90) }
                    }
                    Button("Relative +2 min") {
                        Task { await service.scheduleRelative(minutesFromNow: 2) }
                    }
                    Button("Cancel all", role: .destructive) {
                        service.cancelAll()
                    }
                }

                Section("Killed-app checklist") {
                    Text(
                        """
                        1. Request authorization (expect prompt once).
                        2. Schedule Fixed in 90s.
                        3. Force-quit this app (swipe up from app switcher).
                        4. Lock the phone; leave Silent / Focus on if you want a hard test.
                        5. Wait — did a system alarm UI appear and sound?
                        6. Note: Stop/Snooze on system UI still dismisses without your QR scan.
                        """
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }

                if let err = service.lastError {
                    Section("Last error") {
                        Text(err)
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(.red)
                    }
                }

                Section("Alarms (\(service.alarms.count))") {
                    if service.alarms.isEmpty {
                        Text("None").foregroundStyle(.secondary)
                    } else {
                        ForEach(service.alarms, id: \.id) { alarm in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(alarm.id.uuidString)
                                    .font(.system(.caption2, design: .monospaced))
                                Text("state=\(String(describing: alarm.state))")
                                    .font(.caption)
                                if let schedule = alarm.schedule {
                                    Text("schedule=\(String(describing: schedule))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                Section {
                    Button("Clear log") { service.clearLog() }
                    ForEach(Array(service.logLines.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(.caption2, design: .monospaced))
                    }
                } header: {
                    Text("Log")
                }
            }
            .navigationTitle("AlarmKit Spike")
        }
    }

    private var authLabel: String {
        switch service.authorizationState {
        case .notDetermined: return "notDetermined"
        case .denied: return "denied"
        case .authorized: return "authorized"
        @unknown default: return "unknown"
        }
    }
}

#Preview {
    ContentView()
}

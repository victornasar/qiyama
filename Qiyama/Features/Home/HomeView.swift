import SwiftUI

struct HomeView: View {
    @Environment(AppStore.self) private var store
    @State private var now = Date()
    @State private var showOffset = false
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        let day = store.tonight
        let settings = store.state.settings
        let wakeDate = ISO8601DateFormatter.qiyamaDate(from: day.wakeAtISO)
        let countdownMs = max(0, (wakeDate?.timeIntervalSince(now) ?? 0))
        let due = wakeDate.map { $0 <= now } ?? false
        let windowOpen = Progression.isWakeWindowOpen(day, now: now)
        let done = day.outOfBedAt != nil
        let nextWakeLabel = Schedule.formatTime(day.wakeAtISO, timeZone: settings.timeZone)
        let fajrLabel = Schedule.formatTime(day.fajrISO, timeZone: settings.timeZone)

        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Qiyama")
                        .font(QiyamaTheme.display(28, weight: .semibold))
                        .foregroundStyle(QiyamaTheme.ink)
                    Text(settings.locationLabel)
                        .font(QiyamaTheme.body(14))
                        .foregroundStyle(QiyamaTheme.slate)
                }

                // One job: tonight’s wake. Fajr is context, not a second clock.
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tonight")
                        .font(QiyamaTheme.body(13))
                        .foregroundStyle(QiyamaTheme.slate)

                    Text(nextWakeLabel)
                        .font(QiyamaTheme.display(56, weight: .semibold))
                        .foregroundStyle(QiyamaTheme.lantern)
                        .monospacedDigit()

                    if day.missed {
                        Text("Missed. Next is tomorrow.")
                            .font(QiyamaTheme.body(15))
                            .foregroundStyle(QiyamaTheme.miss)
                    } else if due && done {
                        Text("You got up")
                            .font(QiyamaTheme.body(15))
                            .foregroundStyle(QiyamaTheme.ok)
                    } else if due {
                        Text("Now")
                            .font(QiyamaTheme.body(15, weight: .medium))
                            .foregroundStyle(QiyamaTheme.lantern)
                    } else {
                        Text("in \(Schedule.formatCountdown(ms: countdownMs))")
                            .font(QiyamaTheme.body(15))
                            .foregroundStyle(QiyamaTheme.slate)
                            .monospacedDigit()
                    }

                    Button {
                        showOffset = true
                    } label: {
                        Text("Fajr \(fajrLabel) · \(settings.offsetMinutes) min before")
                            .font(QiyamaTheme.body(14))
                            .foregroundStyle(QiyamaTheme.slate)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Edit wake time before Fajr")
                }

                if due && windowOpen && !done && !day.missed {
                    Button {
                        store.activateIntervention(dateKey: day.dateKey)
                    } label: {
                        Text("I'm awake. Begin")
                            .font(QiyamaTheme.body(17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .foregroundStyle(QiyamaTheme.wakeText)
                            .background(QiyamaTheme.ink)
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Button {
                        Task { await store.startPracticeWake() }
                    } label: {
                        Text("Practice wake now")
                            .font(QiyamaTheme.body(15, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(QiyamaTheme.slate)
                            .overlay(Rectangle().stroke(QiyamaTheme.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    Text("Same flow. Doesn’t count.")
                        .font(QiyamaTheme.body(13))
                        .foregroundStyle(QiyamaTheme.slate)
                }
                .padding(.top, due && windowOpen && !done && !day.missed ? 0 : 8)
            }
            .padding(24)
        }
        .background(QiyamaTheme.paper.ignoresSafeArea())
        .onReceive(timer) { now = $0 }
        .sheet(isPresented: $showOffset) {
            NavigationStack {
                ProfileOffsetView()
            }
            .presentationDetents([.medium, .large])
        }
    }
}

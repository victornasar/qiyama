import SwiftUI

struct ProgressScreen: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        let p = store.state.progress
        let length = store.state.settings.programLengthDays
        let fraction = length > 0 ? min(1, Double(max(p.programDay, 1)) / Double(length)) : 0
        let settings = store.state.settings
        let nextWake = Schedule.formatTime(store.tonight.wakeAtISO, timeZone: settings.timeZone)
        let hasAny = p.totalWakeSuccess > 0 || p.totalPrayed > 0 || p.totalMissed > 0

        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("Progress")
                    .font(QiyamaTheme.body(13))
                    .foregroundStyle(QiyamaTheme.slate)

                // Phase is the story. Page chrome stays quiet.
                VStack(alignment: .leading, spacing: 8) {
                    Text(p.phase.label)
                        .font(QiyamaTheme.display(34, weight: .semibold))
                        .foregroundStyle(QiyamaTheme.ink)
                    Text(p.phase.blurb)
                        .font(QiyamaTheme.body(15))
                        .foregroundStyle(QiyamaTheme.slate)

                    phaseLadder(current: p.phase)
                        .padding(.top, 4)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Day \(max(p.programDay, 1)) of \(length)")
                        .font(QiyamaTheme.body(15))
                        .foregroundStyle(QiyamaTheme.slate)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle().fill(QiyamaTheme.line)
                            Rectangle()
                                .fill(QiyamaTheme.lantern)
                                .frame(width: max(4, geo.size.width * fraction))
                        }
                    }
                    .frame(height: 3)
                }

                VStack(alignment: .leading, spacing: 14) {
                    stat("Out of bed", "\(p.totalWakeSuccess)")
                    stat("Streak", "\(p.consecutiveWakeStreak)")
                    stat("Missed", "\(p.totalMissed)")
                }

                if !hasAny {
                    Text("Nothing logged yet. Streak starts with the next wake.")
                        .font(QiyamaTheme.body(14))
                        .foregroundStyle(QiyamaTheme.slate)
                }

                if p.consecutiveMissStreak > 0 {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Missed \(p.consecutiveMissStreak) in a row. Next morning is what matters.")
                            .font(QiyamaTheme.body(14))
                            .foregroundStyle(QiyamaTheme.miss)
                        Text("Next wake \(nextWake)")
                            .font(QiyamaTheme.body(15, weight: .medium))
                            .foregroundStyle(QiyamaTheme.ink)
                    }
                } else if hasAny {
                    Text("Misses reset the streak, not the program.")
                        .font(QiyamaTheme.body(13))
                        .foregroundStyle(QiyamaTheme.slate)
                }
            }
            .padding(24)
        }
        .background(QiyamaTheme.paper.ignoresSafeArea())
    }

    private func phaseLadder(current: TrainingPhase) -> some View {
        let phases = TrainingPhase.allCases
        return HStack(spacing: 0) {
            ForEach(Array(phases.enumerated()), id: \.element) { index, phase in
                Text(phase.label)
                    .font(QiyamaTheme.body(11, weight: phase == current ? .semibold : .regular))
                    .foregroundStyle(phase == current ? QiyamaTheme.ink : QiyamaTheme.slate.opacity(0.55))
                if index < phases.count - 1 {
                    Text(" · ")
                        .font(QiyamaTheme.body(11))
                        .foregroundStyle(QiyamaTheme.line)
                }
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.85)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(QiyamaTheme.body(15))
                .foregroundStyle(QiyamaTheme.slate)
            Spacer()
            Text(value)
                .font(QiyamaTheme.display(22, weight: .medium))
                .foregroundStyle(QiyamaTheme.ink)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
        .overlay(alignment: .bottom) {
            Rectangle().fill(QiyamaTheme.line).frame(height: 1)
        }
    }
}

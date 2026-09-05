import SwiftUI

struct HistoryView: View {
    @Environment(AppStore.self) private var store

    private var logged: [DayOutcome] {
        Progression.sortedDays(store.state.days).filter { day in
            day.outOfBedAt != nil || day.missed
        }
    }

    private var stripDays: [HistoryDayCell] {
        HistoryViz.lastDays(count: 28, outcomes: store.state.days)
    }

    private var upCount: Int { logged.filter { $0.outOfBedAt != nil && !$0.missed }.count }
    private var missCount: Int { logged.filter { $0.missed }.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("History")
                        .font(QiyamaTheme.display(34, weight: .semibold))
                        .foregroundStyle(QiyamaTheme.ink)
                    Text("Out of bed is what counts.")
                        .font(QiyamaTheme.body(14))
                        .foregroundStyle(QiyamaTheme.slate)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Last 28 mornings")
                        .font(QiyamaTheme.body(13))
                        .foregroundStyle(QiyamaTheme.slate)

                    HistoryRhythmStrip(cells: stripDays)

                    HistoryLegend()

                    if logged.isEmpty {
                        Text("After tomorrow’s wake.")
                            .font(QiyamaTheme.body(14))
                            .foregroundStyle(QiyamaTheme.slate)
                    } else {
                        Text(summaryLine)
                            .font(QiyamaTheme.body(14))
                            .foregroundStyle(QiyamaTheme.ink)
                    }
                }

                if !logged.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Mornings")
                            .font(QiyamaTheme.body(13))
                            .foregroundStyle(QiyamaTheme.slate)
                            .padding(.bottom, 8)

                        ForEach(logged) { day in
                            HistoryRow(day: day)
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(QiyamaTheme.paper.ignoresSafeArea())
    }

    private var summaryLine: String {
        var parts: [String] = ["\(logged.count) logged"]
        if upCount > 0 { parts.append("\(upCount) up") }
        if missCount > 0 { parts.append("\(missCount) missed") }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Rhythm strip

private struct HistoryDayCell: Identifiable {
    let id: String
    let dateKey: String
    let kind: Kind

    enum Kind {
        case empty
        case missed
        case up
    }
}

private enum HistoryViz {
    static func lastDays(count: Int, outcomes: [String: DayOutcome]) -> [HistoryDayCell] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<count).reversed().map { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: today) ?? today
            let key = Schedule.dateKey(from: date)
            let kind: HistoryDayCell.Kind
            if let day = outcomes[key] {
                if day.missed {
                    kind = .missed
                } else if day.outOfBedAt != nil {
                    kind = .up
                } else {
                    kind = .empty
                }
            } else {
                kind = .empty
            }
            return HistoryDayCell(id: key, dateKey: key, kind: kind)
        }
    }
}

private struct HistoryRhythmStrip: View {
    let cells: [HistoryDayCell]

    private let columns = Array(repeating: GridItem(.flexible(minimum: 8), spacing: 4), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(cells) { cell in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(fill(for: cell.kind))
                    .aspectRatio(1, contentMode: .fit)
                    .accessibilityLabel(label(for: cell))
            }
        }
    }

    private func fill(for kind: HistoryDayCell.Kind) -> Color {
        switch kind {
        case .empty: return QiyamaTheme.line.opacity(0.55)
        case .missed: return QiyamaTheme.miss.opacity(0.75)
        case .up: return QiyamaTheme.ok
        }
    }

    private func label(for cell: HistoryDayCell) -> String {
        switch cell.kind {
        case .empty: return "\(cell.dateKey), no log"
        case .missed: return "\(cell.dateKey), missed"
        case .up: return "\(cell.dateKey), out of bed"
        }
    }
}

private struct HistoryLegend: View {
    var body: some View {
        HStack(spacing: 14) {
            legendSwatch(QiyamaTheme.ok, filled: true, title: "Up")
            legendSwatch(QiyamaTheme.miss.opacity(0.75), filled: true, title: "Missed")
            legendSwatch(QiyamaTheme.line.opacity(0.55), filled: true, title: "None")
        }
        .font(QiyamaTheme.body(12))
        .foregroundStyle(QiyamaTheme.slate)
    }

    private func legendSwatch(_ color: Color, filled: Bool, title: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(filled ? color : Color.clear)
                .overlay {
                    if !filled {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .stroke(color, lineWidth: 1.5)
                    }
                }
                .frame(width: 10, height: 10)
            Text(title)
        }
    }
}

// MARK: - Row

private struct HistoryRow: View {
    let day: DayOutcome

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Self.displayDate(day.dateKey))
                    .font(QiyamaTheme.body(15))
                    .foregroundStyle(QiyamaTheme.ink)
                Text(day.dateKey)
                    .font(QiyamaTheme.body(12))
                    .foregroundStyle(QiyamaTheme.slate.opacity(0.7))
            }
            Spacer()
            Text(day.missed ? "Miss" : "Up")
                .font(QiyamaTheme.body(14, weight: .medium))
                .foregroundStyle(day.missed ? QiyamaTheme.miss : QiyamaTheme.ok)
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(QiyamaTheme.line).frame(height: 1)
        }
    }

    private static func displayDate(_ key: String) -> String {
        let date = Schedule.parseDateKey(key)
        let f = DateFormatter()
        f.dateFormat = "EEE d MMM"
        return f.string(from: date)
    }
}

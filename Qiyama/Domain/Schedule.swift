import Foundation

enum Schedule {
    static func dateKey(from date: Date) -> String {
        let cal = Calendar.current
        let y = cal.component(.year, from: date)
        let m = cal.component(.month, from: date)
        let d = cal.component(.day, from: date)
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    static func parseDateKey(_ key: String) -> Date {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return Date() }
        var comps = DateComponents()
        comps.year = parts[0]
        comps.month = parts[1]
        comps.day = parts[2]
        return Calendar.current.date(from: comps) ?? Date()
    }

    static func wakeFromFajr(_ fajr: Date, offsetMinutes: Int) -> Date {
        let minutes = Double(max(OffsetMinutes.clamp(offsetMinutes), 1))
        let wake = fajr.addingTimeInterval(-(minutes * 60))
        if wake >= fajr {
            return fajr.addingTimeInterval(-60)
        }
        return wake
    }

    static func buildDayOutcome(
        settings: Settings,
        dayAnchor: Date,
        phase: TrainingPhase,
        assistanceLevel: AssistanceLevel,
        existing: DayOutcome? = nil
    ) -> DayOutcome {
        let fajr = Prayer.fajr(
            for: dayAnchor,
            latitude: settings.latitude,
            longitude: settings.longitude,
            method: settings.calculationMethod
        )
        let wakeAt = wakeFromFajr(fajr, offsetMinutes: settings.offsetMinutes)
        return DayOutcome(
            dateKey: dateKey(from: dayAnchor),
            fajrISO: ISO8601DateFormatter.qiyama.string(from: fajr),
            wakeAtISO: ISO8601DateFormatter.qiyama.string(from: wakeAt),
            offsetMinutes: settings.offsetMinutes,
            calculationMethod: settings.calculationMethod,
            latitude: settings.latitude,
            longitude: settings.longitude,
            assistanceLevel: assistanceLevel,
            phase: phase,
            outOfBedAt: existing?.outOfBedAt,
            prayed: existing?.prayed,
            missed: existing?.missed ?? false,
            notificationId: existing?.notificationId
        )
    }

    static func ensureTonightSchedule(
        settings: Settings,
        days: [String: DayOutcome],
        phase: TrainingPhase,
        assistanceLevel: AssistanceLevel,
        now: Date = Date()
    ) -> (day: DayOutcome, days: [String: DayOutcome]) {
        let (_, dayAnchor) = Prayer.nextFajr(
            now: now,
            latitude: settings.latitude,
            longitude: settings.longitude,
            method: settings.calculationMethod
        )
        let key = dateKey(from: dayAnchor)
        let day = buildDayOutcome(
            settings: settings,
            dayAnchor: dayAnchor,
            phase: phase,
            assistanceLevel: assistanceLevel,
            existing: days[key]
        )
        var next = days
        next[key] = day
        return (day, next)
    }

    static func tahajjudWindowMinutes(_ day: DayOutcome) -> Int {
        guard let fajr = ISO8601DateFormatter.qiyama.date(from: day.fajrISO),
              let wake = ISO8601DateFormatter.qiyama.date(from: day.wakeAtISO)
        else { return 0 }
        return max(0, Int(round(fajr.timeIntervalSince(wake) / 60)))
    }

    static func formatTime(_ isoOrDate: String, timeZone: String? = nil) -> String {
        guard let date = ISO8601DateFormatter.qiyama.date(from: isoOrDate) else { return isoOrDate }
        return formatTime(date, timeZone: timeZone)
    }

    static func formatTime(_ date: Date, timeZone: String? = nil) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        if let timeZone, let tz = TimeZone(identifier: timeZone) {
            f.timeZone = tz
        }
        return f.string(from: date)
    }

    static func formatCountdown(ms: TimeInterval) -> String {
        if ms <= 0 { return "0m" }
        let totalMin = Int(ms / 60)
        let h = totalMin / 60
        let m = totalMin % 60
        if h <= 0 { return "\(m)m" }
        return "\(h)h \(m)m"
    }
}

extension ISO8601DateFormatter {
    static let qiyama: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func qiyamaDate(from string: String) -> Date? {
        if let d = qiyama.date(from: string) { return d }
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return withFraction.date(from: string)
    }
}

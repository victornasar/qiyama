import Foundation

enum Progression {
    static func assistance(for phase: TrainingPhase) -> AssistanceLevel {
        switch phase {
        case .scaffolded: return 3
        case .steady: return 2
        case .softening: return 1
        case .standing: return 0
        }
    }

    static func emptyProgress(programStart: String?, now: Date = Date()) -> ProgressSnapshot {
        ProgressSnapshot(
            phase: .scaffolded,
            assistanceLevel: 3,
            consecutiveWakeStreak: 0,
            consecutiveMissStreak: 0,
            totalWakeSuccess: 0,
            totalPrayed: 0,
            totalMissed: 0,
            programDay: programDayNumber(programStart, now: now)
        )
    }

    static func programDayNumber(_ programStart: String?, now: Date = Date()) -> Int {
        guard let programStart else { return 0 }
        let start = Schedule.parseDateKey(programStart)
        let today = Calendar.current.startOfDay(for: now)
        let startDay = Calendar.current.startOfDay(for: start)
        let diff = Calendar.current.dateComponents([.day], from: startDay, to: today).day ?? 0
        return max(1, diff + 1)
    }

    static func applyWakeSuccess(
        progress: ProgressSnapshot,
        day: DayOutcome,
        recentDays: [DayOutcome],
        programStart: String?,
        now: Date = Date()
    ) -> ProgressSnapshot {
        let consecutiveWakeStreak = progress.consecutiveWakeStreak + 1
        let totalWakeSuccess = progress.totalWakeSuccess + 1
        var totalPrayed = progress.totalPrayed
        if day.prayed == true { totalPrayed += 1 }

        var phase = progress.phase
        // Weaning is earned by leaving bed — not by logging prayer.
        if phase == .scaffolded && consecutiveWakeStreak >= 7 {
            phase = .steady
        } else if phase == .steady && consecutiveWakeStreak >= 21 {
            phase = .softening
        } else if phase == .softening && consecutiveWakeStreak >= 14 {
            phase = .standing
        }

        return ProgressSnapshot(
            phase: phase,
            assistanceLevel: assistance(for: phase),
            consecutiveWakeStreak: consecutiveWakeStreak,
            consecutiveMissStreak: 0,
            totalWakeSuccess: totalWakeSuccess,
            totalPrayed: totalPrayed,
            totalMissed: progress.totalMissed,
            programDay: programDayNumber(programStart, now: now)
        )
    }

    static func applyMiss(
        progress: ProgressSnapshot,
        programStart: String?,
        now: Date = Date()
    ) -> ProgressSnapshot {
        let consecutiveMissStreak = progress.consecutiveMissStreak + 1
        var phase = progress.phase
        if consecutiveMissStreak >= 3 && phase != .scaffolded {
            phase = stepBack(phase)
        }
        return ProgressSnapshot(
            phase: phase,
            assistanceLevel: assistance(for: phase),
            consecutiveWakeStreak: 0,
            consecutiveMissStreak: consecutiveMissStreak,
            totalWakeSuccess: progress.totalWakeSuccess,
            totalPrayed: progress.totalPrayed,
            totalMissed: progress.totalMissed + 1,
            programDay: programDayNumber(programStart, now: now)
        )
    }

    static func applyPrayerConfirm(progress: ProgressSnapshot, prayed: Bool) -> ProgressSnapshot {
        guard prayed else { return progress }
        var next = progress
        next.totalPrayed += 1
        return next
    }

    static func requiresPhysicalProof(_ level: AssistanceLevel) -> Bool {
        level >= 1
    }

    static func sortedDays(_ days: [String: DayOutcome]) -> [DayOutcome] {
        Array(days.values).sorted { $0.dateKey > $1.dateKey }
    }

    static func isWakeWindowOpen(_ day: DayOutcome, now: Date = Date()) -> Bool {
        guard let wake = ISO8601DateFormatter.qiyamaDate(from: day.wakeAtISO),
              let fajr = ISO8601DateFormatter.qiyamaDate(from: day.fajrISO)
        else { return false }
        let t = now.timeIntervalSince1970
        return t >= wake.timeIntervalSince1970 - 60 && t <= fajr.timeIntervalSince1970 + 30 * 60
    }

    static func shouldMarkMissed(_ day: DayOutcome, now: Date = Date()) -> Bool {
        if day.outOfBedAt != nil || day.missed { return false }
        guard let fajr = ISO8601DateFormatter.qiyamaDate(from: day.fajrISO) else { return false }
        return now.timeIntervalSince1970 > fajr.timeIntervalSince1970 + 30 * 60
    }

    private static func stepBack(_ phase: TrainingPhase) -> TrainingPhase {
        switch phase {
        case .standing: return .softening
        case .softening: return .steady
        case .steady: return .scaffolded
        case .scaffolded: return .scaffolded
        }
    }

    private static func recentSuccessfulWakes(_ days: [DayOutcome], n: Int) -> [DayOutcome] {
        days
            .filter { $0.outOfBedAt != nil && !$0.missed }
            .sorted { $0.dateKey > $1.dateKey }
            .prefix(n)
            .map { $0 }
    }
}

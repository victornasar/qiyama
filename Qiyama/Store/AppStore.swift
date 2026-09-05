import Foundation
import Observation

@MainActor
@Observable
final class AppStore {
    private(set) var ready = false
    var state: AppState

    var tonight: DayOutcome {
        let result = Schedule.ensureTonightSchedule(
            settings: state.settings,
            days: state.days,
            phase: state.progress.phase,
            assistanceLevel: state.progress.assistanceLevel
        )
        return state.days[result.day.dateKey] ?? result.day
    }

    var showSetup: Bool { !state.settings.onboardingComplete }
    var showWake: Bool { state.interventionActiveDateKey != nil }

    init() {
        state = Persistence.freshState()
    }

    func bootstrap() async {
        var loaded = Persistence.load()
        let scheduled = Schedule.ensureTonightSchedule(
            settings: loaded.settings,
            days: loaded.days,
            phase: loaded.progress.phase,
            assistanceLevel: loaded.progress.assistanceLevel
        )
        var day = scheduled.day
        let notificationId = await WakeNotifications.schedule(for: day)
        day.notificationId = notificationId
        var days = scheduled.days
        days[day.dateKey] = day
        loaded.days = days
        loaded.progress.programDay = Progression.programDayNumber(loaded.settings.programStartDate)
        loaded.practiceActive = false
        state = loaded
        Persistence.save(state)
        await markMissedIfNeeded()
        maybeAutoActivate()
        if state.interventionActiveDateKey != nil {
            WakeAudioController.shared.start()
        }
        ready = true
    }

    private func persist(_ next: AppState) {
        state = next
        Persistence.save(next)
    }

    func updateSettings(_ patch: (inout Settings) -> Void) async {
        var settings = state.settings
        patch(&settings)
        let scheduled = Schedule.ensureTonightSchedule(
            settings: settings,
            days: state.days,
            phase: state.progress.phase,
            assistanceLevel: state.progress.assistanceLevel
        )
        await WakeNotifications.cancel(state.days[scheduled.day.dateKey]?.notificationId)
        var day = scheduled.day
        day.notificationId = await WakeNotifications.schedule(for: day)
        var days = scheduled.days
        days[day.dateKey] = day
        persist(AppState(
            settings: settings,
            days: days,
            progress: state.progress,
            interventionActiveDateKey: state.interventionActiveDateKey,
            practiceActive: state.practiceActive
        ))
    }

    func setOffset(_ offset: Int) async {
        await updateSettings { $0.offsetMinutes = OffsetMinutes.clamp(offset) }
    }

    func setLocation(_ choice: LocationChoice) async {
        await updateSettings {
            $0.locationId = choice.id
            $0.latitude = choice.latitude
            $0.longitude = choice.longitude
            $0.timeZone = choice.timeZone
            $0.locationLabel = choice.label
        }
    }

    func restartOnboarding() {
        WakeAudioController.shared.stop()
        var settings = QR.defaultSettings()
        settings.verifyToken = state.settings.verifyToken
        persist(AppState(
            settings: settings,
            days: [:],
            progress: Progression.emptyProgress(programStart: nil),
            interventionActiveDateKey: nil,
            practiceActive: false
        ))
    }

    func startProgram() async {
        let today = Schedule.dateKey(from: Date())
        var settings = state.settings
        settings.programStartDate = today
        settings.onboardingComplete = true
        let progress = Progression.emptyProgress(programStart: today)
        let scheduled = Schedule.ensureTonightSchedule(
            settings: settings,
            days: state.days,
            phase: progress.phase,
            assistanceLevel: progress.assistanceLevel
        )
        var day = scheduled.day
        day.notificationId = await WakeNotifications.schedule(for: day)
        var days = scheduled.days
        days[day.dateKey] = day
        persist(AppState(
            settings: settings,
            days: days,
            progress: progress,
            interventionActiveDateKey: nil,
            practiceActive: false
        ))
    }

    func activateIntervention(dateKey: String) {
        WakeAudioController.shared.start()
        var next = state
        next.interventionActiveDateKey = dateKey
        next.practiceActive = false
        persist(next)
    }

    func startPracticeWake() {
        let day = tonight
        WakeAudioController.shared.start()
        var next = state
        next.interventionActiveDateKey = day.dateKey
        next.practiceActive = true
        persist(next)
    }

    func endPractice() {
        WakeAudioController.shared.stop()
        var next = state
        next.interventionActiveDateKey = nil
        next.practiceActive = false
        persist(next)
    }

    func clearIntervention() {
        WakeAudioController.shared.stop()
        var next = state
        next.interventionActiveDateKey = nil
        next.practiceActive = false
        persist(next)
    }

    func markOutOfBed(dateKey: String) {
        guard !state.practiceActive else { return }
        guard var day = state.days[dateKey], day.outOfBedAt == nil else { return }
        day.outOfBedAt = ISO8601DateFormatter.qiyama.string(from: Date())
        day.missed = false
        var days = state.days
        days[dateKey] = day
        let progress = Progression.applyWakeSuccess(
            progress: state.progress,
            day: day,
            recentDays: Progression.sortedDays(days),
            programStart: state.settings.programStartDate
        )
        var next = state
        next.days = days
        next.progress = progress
        persist(next)
    }

    func confirmPrayed(dateKey: String, prayed: Bool) {
        if state.practiceActive {
            clearIntervention()
            return
        }
        guard var day = state.days[dateKey] else { return }
        let alreadyCounted = day.prayed == true
        day.prayed = prayed
        var days = state.days
        days[dateKey] = day
        var progress = state.progress
        if prayed && !alreadyCounted {
            progress = Progression.applyPrayerConfirm(progress: progress, prayed: true)
        }
        WakeAudioController.shared.stop()
        persist(AppState(
            settings: state.settings,
            days: days,
            progress: progress,
            interventionActiveDateKey: nil,
            practiceActive: false
        ))
    }

    func markMissed(dateKey: String) {
        if state.practiceActive {
            endPractice()
            return
        }
        guard var day = state.days[dateKey], day.outOfBedAt == nil else { return }
        day.missed = true
        var days = state.days
        days[dateKey] = day
        let progress = Progression.applyMiss(
            progress: state.progress,
            programStart: state.settings.programStartDate
        )
        WakeAudioController.shared.stop()
        persist(AppState(
            settings: state.settings,
            days: days,
            progress: progress,
            interventionActiveDateKey: nil,
            practiceActive: false
        ))
    }

    func markMissedIfNeeded() async {
        var days = state.days
        var progress = state.progress
        var changed = false
        for day in Array(days.values) {
            if Progression.shouldMarkMissed(day) {
                var updated = day
                updated.missed = true
                days[day.dateKey] = updated
                progress = Progression.applyMiss(
                    progress: progress,
                    programStart: state.settings.programStartDate
                )
                changed = true
            }
        }
        if changed {
            var next = state
            next.days = days
            next.progress = progress
            persist(next)
        }
    }

    func regenerateVerifyToken() async {
        await updateSettings { $0.verifyToken = QR.createToken() }
    }

    /// Bind an already-printed mark (e.g. from Expo) as the current token.
    func adoptPrintedMark(fromScan data: String) async -> Bool {
        guard let token = QR.parseToken(from: data) else { return false }
        await updateSettings { $0.verifyToken = token }
        return true
    }

    func maybeAutoActivate() {
        let day = tonight
        guard state.interventionActiveDateKey == nil else { return }
        guard day.outOfBedAt == nil, !day.missed else { return }
        guard Progression.isWakeWindowOpen(day) else { return }
        guard let wake = ISO8601DateFormatter.qiyamaDate(from: day.wakeAtISO), wake <= Date() else { return }
        activateIntervention(dateKey: day.dateKey)
    }

    func handleNotification(dateKey: String) {
        activateIntervention(dateKey: dateKey)
    }
}

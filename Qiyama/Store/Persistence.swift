import Foundation

enum Persistence {
    static let key = "qiyama:v1"

    static func freshState() -> AppState {
        let settings = QR.defaultSettings()
        return AppState(
            settings: settings,
            days: [:],
            progress: Progression.emptyProgress(programStart: nil),
            interventionActiveDateKey: nil,
            practiceActive: false
        )
    }

    static func load() -> AppState {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return freshState()
        }
        do {
            let decoded = try JSONDecoder().decode(AppState.self, from: data)
            var settings = QR.defaultSettings()
            // Merge defaults under loaded settings
            settings = decoded.settings
            settings.offsetMinutes = OffsetMinutes.clamp(settings.offsetMinutes)
            let progressBase = Progression.emptyProgress(programStart: settings.programStartDate)
            var progress = decoded.progress
            if progress.programDay == 0 {
                progress.programDay = progressBase.programDay
            }
            return AppState(
                settings: settings,
                days: decoded.days,
                progress: progress,
                interventionActiveDateKey: decoded.interventionActiveDateKey,
                practiceActive: false // practice never survives relaunch
            )
        } catch {
            return freshState()
        }
    }

    static func save(_ state: AppState) {
        do {
            let data = try JSONEncoder().encode(state)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            // ignore encode failures
        }
    }
}

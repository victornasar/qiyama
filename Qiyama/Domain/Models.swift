import Foundation

enum CalculationMethodId: String, Codable, CaseIterable, Identifiable {
    case isna, mwl, egyptian, ummAlQura, karachi
    var id: String { rawValue }

    var label: String {
        switch self {
        case .isna: return "ISNA (North America)"
        case .mwl: return "Muslim World League"
        case .egyptian: return "Egyptian"
        case .ummAlQura: return "Umm al-Qura"
        case .karachi: return "Karachi"
        }
    }

    var shortLabel: String {
        switch self {
        case .isna: return "ISNA"
        case .mwl: return "MWL"
        case .egyptian: return "Egyptian"
        case .ummAlQura: return "Umm al-Qura"
        case .karachi: return "Karachi"
        }
    }
}

enum TrainingPhase: String, Codable, CaseIterable {
    case scaffolded, steady, softening, standing

    var label: String {
        switch self {
        case .scaffolded: return "Scaffolded"
        case .steady: return "Steady"
        case .softening: return "Softening"
        case .standing: return "Standing"
        }
    }

    var blurb: String {
        switch self {
        case .scaffolded: return "Walk to your mark. Scan every morning."
        case .steady: return "Same walk. Building the automatic pull out of bed."
        case .softening: return "Assistance drops. Testing whether the habit holds."
        case .standing: return "Reminder only. The goal is waking without this app."
        }
    }
}

typealias AssistanceLevel = Int // 3, 2, 1, 0

/// Minutes before Fajr. Stored as Int; presets drive chips, slider covers the range.
enum OffsetMinutes {
    static let presets = [15, 30, 45, 60, 75, 90]
    static let minimum = 15
    static let maximum = 90
    static let `default` = 45

    static func clamp(_ value: Int) -> Int {
        min(maximum, max(minimum, value))
    }

    static func label(_ minutes: Int) -> String {
        "\(minutes) minutes before Fajr"
    }
}

struct LocationPreset: Identifiable, Hashable {
    let id: String
    let label: String
    let latitude: Double
    let longitude: Double
    let timeZone: String
}

struct Settings: Codable, Equatable {
    var locationId: String
    var latitude: Double
    var longitude: Double
    var timeZone: String
    var locationLabel: String
    var calculationMethod: CalculationMethodId
    var offsetMinutes: Int
    var programLengthDays: Int
    var programStartDate: String?
    var onboardingComplete: Bool
    var verifyToken: String
}

struct DayOutcome: Codable, Equatable, Identifiable {
    var id: String { dateKey }
    var dateKey: String
    var fajrISO: String
    var wakeAtISO: String
    var offsetMinutes: Int
    var calculationMethod: CalculationMethodId
    var latitude: Double
    var longitude: Double
    var assistanceLevel: AssistanceLevel
    var phase: TrainingPhase
    var outOfBedAt: String?
    var prayed: Bool?
    var missed: Bool
    var notificationId: String?
}

struct ProgressSnapshot: Codable, Equatable {
    var phase: TrainingPhase
    var assistanceLevel: AssistanceLevel
    var consecutiveWakeStreak: Int
    var consecutiveMissStreak: Int
    var totalWakeSuccess: Int
    var totalPrayed: Int
    var totalMissed: Int
    var programDay: Int
}

struct AppState: Codable, Equatable {
    var settings: Settings
    var days: [String: DayOutcome]
    var progress: ProgressSnapshot
    var interventionActiveDateKey: String?
    var practiceActive: Bool
}

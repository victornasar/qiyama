import Foundation

enum QR {
    static let scheme = "qiyama-verify"

    static func buildPayload(token: String) -> String {
        "\(scheme):\(token)"
    }

    static func isValidScan(_ data: String, token: String) -> Bool {
        guard let scanned = parseToken(from: data) else { return false }
        return scanned == token
    }

    /// Accepts `qiyama-verify:token`, bare token, or URL-ish wrappers.
    static func parseToken(from data: String) -> String? {
        var trimmed = data.trimmingCharacters(in: .whitespacesAndNewlines)
        if let prefix = trimmed.range(of: "\(scheme):", options: .caseInsensitive) {
            trimmed = String(trimmed[prefix.upperBound...])
        }
        trimmed = trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789")
        guard trimmed.count == 10,
              trimmed.lowercased().unicodeScalars.allSatisfy({ allowed.contains($0) })
        else { return nil }
        return trimmed.lowercased()
    }

    static func createToken() -> String {
        let alphabet = Array("abcdefghijklmnopqrstuvwxyz0123456789")
        return String((0..<10).map { _ in alphabet.randomElement()! })
    }

    static func defaultSettings() -> Settings {
        Settings(
            locationId: LocationPresets.sanDiego.id,
            latitude: LocationPresets.sanDiego.latitude,
            longitude: LocationPresets.sanDiego.longitude,
            timeZone: LocationPresets.sanDiego.timeZone,
            locationLabel: LocationPresets.sanDiego.label,
            calculationMethod: .isna,
            offsetMinutes: OffsetMinutes.default,
            programLengthDays: 90,
            programStartDate: nil,
            onboardingComplete: false,
            verifyToken: createToken()
        )
    }
}

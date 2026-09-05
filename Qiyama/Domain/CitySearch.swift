import Foundation
import MapKit
import Observation

struct LocationChoice: Identifiable, Hashable {
    var id: String
    var label: String
    var latitude: Double
    var longitude: Double
    var timeZone: String

    static func fromPreset(_ preset: LocationPreset) -> LocationChoice {
        LocationChoice(
            id: preset.id,
            label: preset.label,
            latitude: preset.latitude,
            longitude: preset.longitude,
            timeZone: preset.timeZone
        )
    }
}

@MainActor
@Observable
final class CitySearchModel: NSObject, MKLocalSearchCompleterDelegate {
    var query = ""
    var results: [MKLocalSearchCompletion] = []
    var isSearching = false
    var resolveError: String?

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
        // Cities only — no streets, postal codes, or POIs.
        completer.addressFilter = MKAddressFilter(including: .locality)
    }

    func updateQuery(_ value: String) {
        query = value
        resolveError = nil
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count < 2 {
            results = []
            isSearching = false
            completer.queryFragment = ""
            return
        }
        isSearching = true
        completer.queryFragment = trimmed
    }

    func clear() {
        query = ""
        results = []
        isSearching = false
        resolveError = nil
        completer.queryFragment = ""
    }

    func resolve(_ completion: MKLocalSearchCompletion) async -> LocationChoice? {
        isSearching = true
        defer { isSearching = false }
        let request = MKLocalSearch.Request(completion: completion)
        request.resultTypes = .address
        request.addressFilter = MKAddressFilter(including: .locality)
        do {
            let response = try await MKLocalSearch(request: request).start()
            guard let item = response.mapItems.first else {
                resolveError = "Couldn’t place that city."
                return nil
            }
            let coordinate = item.location.coordinate
            let tz = item.timeZone?.identifier ?? TimeZone.current.identifier
            let label = Self.cityLabel(for: completion, item: item)
            return LocationChoice(
                id: "geo:\(String(format: "%.4f", coordinate.latitude)),\(String(format: "%.4f", coordinate.longitude))",
                label: label,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                timeZone: tz
            )
        } catch {
            resolveError = "Search failed. Try again."
            return nil
        }
    }

    private static func cityLabel(for completion: MKLocalSearchCompletion, item: MKMapItem) -> String {
        let title = completion.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let subtitle = completion.subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !title.isEmpty, !subtitle.isEmpty {
            // "CA, United States" → keep region + country short.
            let shortSub = subtitle
                .split(separator: ",")
                .prefix(2)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .joined(separator: ", ")
            return "\(title), \(shortSub)"
        }
        if let name = item.name, !name.isEmpty { return name }
        if !title.isEmpty { return title }
        return "Selected city"
    }

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let next = completer.results.filter(Self.looksLikeCity)
        Task { @MainActor in
            self.results = next
            self.isSearching = false
        }
    }

    /// Extra guard: drop street-like titles that slip past the address filter.
    private static func looksLikeCity(_ completion: MKLocalSearchCompletion) -> Bool {
        let title = completion.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return false }
        if title.rangeOfCharacter(from: .decimalDigits) != nil { return false }
        if title.contains(" St") || title.contains(" Ave") || title.contains(" Rd") || title.contains(" Blvd") {
            return false
        }
        return true
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            self.results = []
            self.isSearching = false
            self.resolveError = "Search failed. Try again."
        }
    }
}

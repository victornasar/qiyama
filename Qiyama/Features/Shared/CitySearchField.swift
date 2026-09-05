import MapKit
import SwiftUI

struct CitySearchField: View {
    @Binding var selection: LocationChoice?
    var autofocus: Bool = false

    @State private var model = CitySearchModel()
    @State private var resolvingId: String?
    @FocusState private var focused: Bool

    private var majorMatches: [LocationPreset] {
        LocationPresets.filtered(query: model.query)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(QiyamaTheme.slate)
                TextField("City", text: Binding(
                    get: { model.query },
                    set: { model.updateQuery($0) }
                ))
                .font(QiyamaTheme.body(17))
                .foregroundStyle(QiyamaTheme.ink)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .focused($focused)
                .submitLabel(.search)

                if !model.query.isEmpty {
                    Button {
                        model.clear()
                        selection = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(QiyamaTheme.slate)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.55))
            .overlay(Rectangle().stroke(QiyamaTheme.line, lineWidth: 1))

            if let selection {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(QiyamaTheme.ok)
                    Text(selection.label)
                        .font(QiyamaTheme.body(15, weight: .medium))
                        .foregroundStyle(QiyamaTheme.ink)
                        .lineLimit(2)
                }
            }

            if let error = model.resolveError {
                Text(error)
                    .font(QiyamaTheme.body(13))
                    .foregroundStyle(QiyamaTheme.miss)
            }

            // Prefer curated major NA cities; MapKit only if typing and nothing local matched.
            if !majorMatches.isEmpty {
                cityList(majorMatches)
            } else if !model.results.isEmpty {
                mapKitResults
            } else if model.isSearching && model.query.count >= 2 {
                ProgressView()
                    .padding(.top, 4)
            }
        }
        .onAppear {
            if autofocus {
                focused = true
            }
            if let selection, model.query.isEmpty {
                model.query = selection.label
            }
        }
    }

    private func cityList(_ cities: [LocationPreset]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if model.query.isEmpty {
                Text("Major cities · North America")
                    .font(QiyamaTheme.body(12))
                    .foregroundStyle(QiyamaTheme.slate)
                    .padding(.bottom, 6)
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(cities) { city in
                        Button {
                            selection = .fromPreset(city)
                            model.query = city.label
                            model.results = []
                            focused = false
                        } label: {
                            Text(city.label)
                                .font(QiyamaTheme.body(16))
                                .foregroundStyle(QiyamaTheme.ink)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 12)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Rectangle().fill(QiyamaTheme.line).frame(height: 1)
                    }
                }
            }
            .frame(maxHeight: 360)
        }
    }

    private var mapKitResults: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(model.results.prefix(8).enumerated()), id: \.offset) { index, result in
                Button {
                    Task { await pick(result) }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.title)
                                .font(QiyamaTheme.body(16, weight: .medium))
                                .foregroundStyle(QiyamaTheme.ink)
                                .multilineTextAlignment(.leading)
                            if !result.subtitle.isEmpty {
                                Text(result.subtitle)
                                    .font(QiyamaTheme.body(13))
                                    .foregroundStyle(QiyamaTheme.slate)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        Spacer(minLength: 8)
                        if resolvingId == resultKey(result) {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(resolvingId != nil)

                if index < min(model.results.count, 8) - 1 {
                    Rectangle().fill(QiyamaTheme.line).frame(height: 1)
                }
            }
        }
    }

    private func resultKey(_ result: MKLocalSearchCompletion) -> String {
        "\(result.title)|\(result.subtitle)"
    }

    private func pick(_ result: MKLocalSearchCompletion) async {
        resolvingId = resultKey(result)
        defer { resolvingId = nil }
        if let choice = await model.resolve(result) {
            selection = choice
            model.query = choice.label
            model.results = []
            focused = false
        }
    }
}

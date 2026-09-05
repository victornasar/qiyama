import SwiftUI

/// Preset chips + continuous slider for minutes before Fajr.
struct OffsetControl: View {
    @Binding var minutes: Int
    var showPresets: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if showPresets {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(OffsetMinutes.presets, id: \.self) { option in
                            Button {
                                minutes = option
                            } label: {
                                Text("\(option)m")
                                    .font(QiyamaTheme.body(15, weight: .medium))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .foregroundStyle(minutes == option ? QiyamaTheme.wakeText : QiyamaTheme.ink)
                                    .background(minutes == option ? QiyamaTheme.ink : Color.clear)
                                    .overlay(
                                        Rectangle()
                                            .stroke(QiyamaTheme.line, lineWidth: minutes == option ? 0 : 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Before Fajr")
                        .font(QiyamaTheme.body(13))
                        .foregroundStyle(QiyamaTheme.slate)
                    Spacer()
                    Text("\(minutes) min")
                        .font(QiyamaTheme.body(15, weight: .medium))
                        .foregroundStyle(QiyamaTheme.ink)
                        .monospacedDigit()
                }

                Slider(
                    value: Binding(
                        get: { Double(minutes) },
                        set: { minutes = OffsetMinutes.clamp(Int($0.rounded())) }
                    ),
                    in: Double(OffsetMinutes.minimum)...Double(OffsetMinutes.maximum),
                    step: 1
                )
                .tint(QiyamaTheme.lantern)
            }
        }
    }
}

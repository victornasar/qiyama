import SwiftUI

struct SetupView: View {
    @Environment(AppStore.self) private var store
    @State private var step = 0
    @State private var location: LocationChoice?
    @State private var offset = OffsetMinutes.default
    @State private var wakeText = ""
    @State private var shareItems: [Any] = []
    @State private var showShare = false
    @State private var printData: Data?
    @State private var showPrint = false
    @State private var didPrintOrShare = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(step + 1) of 3")
                .font(QiyamaTheme.body(13))
                .foregroundStyle(QiyamaTheme.slate)
                .padding(.top, 8)

            Group {
                switch step {
                case 0: locationStep
                case 1: offsetStep
                default: markStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            footer
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(QiyamaTheme.paper.ignoresSafeArea())
        .onAppear {
            let s = store.state.settings
            location = LocationChoice(
                id: s.locationId,
                label: s.locationLabel,
                latitude: s.latitude,
                longitude: s.longitude,
                timeZone: s.timeZone
            )
            offset = OffsetMinutes.clamp(s.offsetMinutes)
            refreshWake()
        }
        .onChange(of: offset) { _, _ in refreshWake() }
        .onChange(of: location) { _, _ in refreshWake() }
        .sheet(isPresented: $showShare) {
            ShareSheet(items: shareItems)
        }
        .background {
            if showPrint, let printData {
                PrintMarkView(data: printData)
                    .frame(width: 0, height: 0)
                    .onAppear { showPrint = false }
            }
        }
    }

    private var locationStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Where are you praying?")
                    .font(QiyamaTheme.display(30, weight: .semibold))
                    .foregroundStyle(QiyamaTheme.ink)
                Text("Used for Fajr time only.")
                    .font(QiyamaTheme.body(15))
                    .foregroundStyle(QiyamaTheme.slate)
            }
            .padding(.top, 20)

            CitySearchField(selection: $location, autofocus: true)
        }
    }

    private var offsetStep: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Wake before Fajr")
                    .font(QiyamaTheme.display(30, weight: .semibold))
                    .foregroundStyle(QiyamaTheme.ink)
                Text(location?.label ?? store.state.settings.locationLabel)
                    .font(QiyamaTheme.body(15))
                    .foregroundStyle(QiyamaTheme.slate)
            }
            .padding(.top, 20)

            OffsetControl(minutes: $offset)

            VStack(alignment: .leading, spacing: 6) {
                Text("Tonight this rings at")
                    .font(QiyamaTheme.body(13))
                    .foregroundStyle(QiyamaTheme.slate)
                Text(wakeText)
                    .font(QiyamaTheme.display(44, weight: .semibold))
                    .foregroundStyle(QiyamaTheme.lantern)
                    .monospacedDigit()
            }
        }
    }

    private var markStep: some View {
        let payload = QR.buildPayload(token: store.state.settings.verifyToken)

        return VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Print your mark")
                    .font(QiyamaTheme.display(30, weight: .semibold))
                    .foregroundStyle(QiyamaTheme.ink)
                Text("Put it somewhere you must walk to — away from the bed.")
                    .font(QiyamaTheme.body(15))
                    .foregroundStyle(QiyamaTheme.slate)
            }
            .padding(.top, 20)

            if let img = MarkFactory.qrImage(payload: payload) {
                Image(uiImage: img)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 180, height: 180)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }

            Text(payload)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(QiyamaTheme.slate)
                .frame(maxWidth: .infinity)
                .textSelection(.enabled)

            VStack(spacing: 10) {
                Button {
                    if let data = MarkFactory.pdfData(payload: payload) {
                        printData = data
                        showPrint = true
                        didPrintOrShare = true
                    }
                } label: {
                    Text("Print")
                        .font(QiyamaTheme.body(17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundStyle(QiyamaTheme.wakeText)
                        .background(QiyamaTheme.ink)
                }
                .buttonStyle(.plain)

                Button {
                    if let data = MarkFactory.pdfData(payload: payload) {
                        let url = FileManager.default.temporaryDirectory.appendingPathComponent("qiyama-mark.pdf")
                        try? data.write(to: url)
                        shareItems = [url]
                        showShare = true
                        didPrintOrShare = true
                    }
                } label: {
                    Text("Share PDF")
                        .font(QiyamaTheme.body(16, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(QiyamaTheme.ink)
                        .overlay(Rectangle().stroke(QiyamaTheme.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            Text("Morning proof is walking to this mark and scanning it.")
                .font(QiyamaTheme.body(14))
                .foregroundStyle(QiyamaTheme.slate)
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button {
                    step -= 1
                } label: {
                    Text("Back")
                        .font(QiyamaTheme.body(17, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundStyle(QiyamaTheme.ink)
                        .overlay(Rectangle().stroke(QiyamaTheme.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            Button {
                Task { await advance() }
            } label: {
                Text(primaryLabel)
                    .font(QiyamaTheme.body(17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(step == 2 && !didPrintOrShare ? QiyamaTheme.ink : QiyamaTheme.wakeText)
                    .background(step == 2 && !didPrintOrShare ? Color.clear : (canAdvance ? QiyamaTheme.ink : QiyamaTheme.slate.opacity(0.35)))
                    .overlay {
                        if step == 2 && !didPrintOrShare {
                            Rectangle().stroke(QiyamaTheme.line, lineWidth: 1)
                        }
                    }
            }
            .buttonStyle(.plain)
            .disabled(!canAdvance)
        }
    }

    private var primaryLabel: String {
        switch step {
        case 0, 1: return "Continue"
        default: return didPrintOrShare ? "Begin" : "Skip for now"
        }
    }

    private var canAdvance: Bool {
        if step == 0 { return location != nil }
        return true
    }

    private func advance() async {
        switch step {
        case 0:
            guard let location else { return }
            await store.setLocation(location)
            step = 1
            refreshWake()
        case 1:
            await store.setOffset(offset)
            step = 2
        default:
            _ = await WakeNotifications.ensureSetup()
            await store.startProgram()
        }
    }

    private func refreshWake() {
        let lat = location?.latitude ?? store.state.settings.latitude
        let lon = location?.longitude ?? store.state.settings.longitude
        let tz = location?.timeZone ?? store.state.settings.timeZone
        let method = store.state.settings.calculationMethod
        let next = Prayer.nextFajr(latitude: lat, longitude: lon, method: method)
        let wake = Schedule.wakeFromFajr(next.fajr, offsetMinutes: offset)
        wakeText = Schedule.formatTime(wake, timeZone: tz)
    }
}

import SwiftUI
import UIKit

struct SetupView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    /// 0 intro · 1 city · 2 offset · 3 permissions · 4 mark
    @State private var step = 0
    @State private var location: LocationChoice?
    @State private var offset = OffsetMinutes.default
    @State private var wakeText = ""
    @State private var shareItems: [Any] = []
    @State private var showShare = false
    @State private var printData: Data?
    @State private var showPrint = false
    @State private var didPrintOrShare = false
    @State private var alarmsAllowed = false
    @State private var notificationsAllowed = false
    @State private var notificationsDenied = false
    @State private var requestingPermissions = false

    private let setupStepCount = 4

    /// Alarms are required. Notifications are optional (Guideline 4.5.4).
    private var canContinuePermissions: Bool { alarmsAllowed }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if step > 0 {
                onboardingProgress
                    .padding(.top, 8)
                    .padding(.bottom, 4)
            }

            Group {
                switch step {
                case 0: introStep
                case 1: locationStep
                case 2: offsetStep
                case 3: permissionsStep
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
            Task { await refreshPermissions() }
            offset = OffsetMinutes.clamp(store.state.settings.offsetMinutes)
            refreshWake()
        }
        .onChange(of: offset) { _, _ in refreshWake() }
        .onChange(of: location) { _, _ in refreshWake() }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await refreshPermissions() }
        }
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

    private var onboardingProgress: some View {
        let index = max(0, step - 1)
        let fraction = Double(index + 1) / Double(setupStepCount)
        return VStack(alignment: .leading, spacing: 8) {
            Text("\(index + 1) of \(setupStepCount)")
                .font(QiyamaTheme.body(13))
                .foregroundStyle(QiyamaTheme.slate)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(QiyamaTheme.line)
                    Rectangle()
                        .fill(QiyamaTheme.lantern)
                        .frame(width: max(4, geo.size.width * fraction))
                }
            }
            .frame(height: 3)
        }
    }

    private var introStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer(minLength: 40)
            Text("Qiyama")
                .font(QiyamaTheme.display(44, weight: .semibold))
                .foregroundStyle(QiyamaTheme.ink)

            Text("Wake before Fajr.")
                .font(QiyamaTheme.display(28, weight: .medium))
                .foregroundStyle(QiyamaTheme.ink)

            Text("Walk to a mark away from the bed. That is the whole product — then slowly stop needing the app.")
                .font(QiyamaTheme.body(16))
                .foregroundStyle(QiyamaTheme.slate)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }

    private var permissionsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("How Qiyama wakes you")
                    .font(QiyamaTheme.display(30, weight: .semibold))
                    .foregroundStyle(QiyamaTheme.ink)
                Text("At \(wakeText.isEmpty ? "wake time" : wakeText), Qiyama has to reach you even if the phone is locked, silent, or the app is closed. Turn on alarms to continue.")
                    .font(QiyamaTheme.body(15))
                    .foregroundStyle(QiyamaTheme.slate)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 16)

            VStack(spacing: 0) {
                permissionToggleRow(
                    title: "Alarms & timers",
                    detail: "Required. Rings through lock screen and silent mode.",
                    isOn: alarmsAllowed,
                    denied: WakeAlarms.isDenied,
                    optional: false,
                    showBorder: true
                ) {
                    await toggleAlarms()
                }
                permissionToggleRow(
                    title: "Notifications",
                    detail: "Optional. A reminder when it is time to walk to your mark.",
                    isOn: notificationsAllowed,
                    denied: notificationsDenied,
                    optional: true,
                    showBorder: false
                ) {
                    await toggleNotifications()
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(QiyamaTheme.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.top, 4)

            if WakeAlarms.isDenied && !alarmsAllowed {
                Text("Alarms are off in Settings. Turn them on for Qiyama, then return here.")
                    .font(QiyamaTheme.body(14))
                    .foregroundStyle(QiyamaTheme.miss)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }

    private func permissionToggleRow(
        title: String,
        detail: String,
        isOn: Bool,
        denied: Bool,
        optional: Bool,
        showBorder: Bool,
        onToggle: @escaping () async -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(QiyamaTheme.body(16, weight: .semibold))
                        .foregroundStyle(QiyamaTheme.ink)
                    if optional {
                        Text("Optional")
                            .font(QiyamaTheme.body(12, weight: .medium))
                            .foregroundStyle(QiyamaTheme.slate)
                    }
                }
                Text(detail)
                    .font(QiyamaTheme.body(13))
                    .foregroundStyle(QiyamaTheme.slate)
                    .fixedSize(horizontal: false, vertical: true)
                if denied && !isOn {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                    .font(QiyamaTheme.body(13, weight: .medium))
                    .foregroundStyle(QiyamaTheme.lantern)
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }
            }
            Spacer(minLength: 8)
            Toggle("", isOn: Binding(
                get: { isOn },
                set: { newValue in
                    guard newValue != isOn else { return }
                    if !newValue {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                        return
                    }
                    Task { await onToggle() }
                }
            ))
            .labelsHidden()
            .tint(QiyamaTheme.lantern)
            .disabled(requestingPermissions)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.45))
        .overlay(alignment: .bottom) {
            if showBorder {
                Rectangle().fill(QiyamaTheme.line).frame(height: 1)
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
            .padding(.top, 16)

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
            .padding(.top, 16)

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
            .padding(.top, 16)

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

            Text("Print or share a mark before you begin — morning proof is walking to it and scanning.")
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
                    .foregroundStyle(canAdvance ? QiyamaTheme.wakeText : QiyamaTheme.ink)
                    .background(canAdvance ? QiyamaTheme.ink : QiyamaTheme.slate.opacity(0.35))
            }
            .buttonStyle(.plain)
            .disabled(!canAdvance || requestingPermissions)
        }
    }

    private var primaryLabel: String {
        switch step {
        case 0, 1, 2, 3:
            return "Continue"
        default:
            return "Begin"
        }
    }

    private var canAdvance: Bool {
        switch step {
        case 1:
            return location != nil
        case 3:
            return canContinuePermissions
        case 4:
            return didPrintOrShare
        default:
            return true
        }
    }

    private func advance() async {
        switch step {
        case 0:
            step = 1
        case 1:
            guard let location else { return }
            await store.setLocation(location)
            step = 2
            refreshWake()
        case 2:
            await store.setOffset(offset)
            await refreshPermissions()
            step = 3
        case 3:
            guard canContinuePermissions else { return }
            step = 4
        default:
            await refreshPermissions()
            guard alarmsAllowed else {
                step = 3
                return
            }
            // Notifications are optional — never gate Begin on them.
            await store.startProgram()
        }
    }

    private func toggleAlarms() async {
        if WakeAlarms.isDenied {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                openURL(url)
            }
            return
        }
        requestingPermissions = true
        _ = await WakeAlarms.ensureAuthorized()
        await refreshPermissions()
        requestingPermissions = false
    }

    private func toggleNotifications() async {
        if notificationsDenied {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                openURL(url)
            }
            return
        }
        requestingPermissions = true
        _ = await WakeNotifications.requestAuthorization()
        await refreshPermissions()
        requestingPermissions = false
    }

    private func refreshPermissions() async {
        alarmsAllowed = WakeAlarms.isAuthorized
        notificationsAllowed = await WakeNotifications.isAuthorized()
        notificationsDenied = await WakeNotifications.isDenied()
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

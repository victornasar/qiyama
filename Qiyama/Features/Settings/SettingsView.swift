import SwiftUI

/// BulkChamps-style profile hub: header + titled sections of rows.
struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @State private var path = NavigationPath()
    @State private var showReplaceConfirm = false
    @State private var showRestartConfirm = false
    @State private var showTestScan = false
    @State private var showAdoptScan = false
    @State private var shareItems: [Any] = []
    @State private var showShare = false
    @State private var printData: Data?
    @State private var showPrint = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Text("Profile")
                        .font(QiyamaTheme.display(34, weight: .semibold))
                        .foregroundStyle(QiyamaTheme.ink)

                    profileHeader

                    sectionCard(title: "Schedule") {
                        ProfileRow(
                            icon: "mappin.and.ellipse",
                            label: "Location",
                            value: store.state.settings.locationLabel,
                            showBorder: true
                        ) {
                            path.append(ProfileRoute.location)
                        }
                        ProfileRow(
                            icon: "alarm",
                            label: "Wake before Fajr",
                            value: "\(store.state.settings.offsetMinutes) min",
                            showBorder: true
                        ) {
                            path.append(ProfileRoute.offset)
                        }
                        ProfileRow(
                            icon: "moon.stars",
                            label: "Calculation",
                            value: store.state.settings.calculationMethod.shortLabel,
                            showBorder: false
                        ) {
                            path.append(ProfileRoute.calculation)
                        }
                    }

                    sectionCard(title: "Your mark") {
                        ProfileRow(icon: "qrcode", label: "Print mark", showBorder: true) {
                            let payload = QR.buildPayload(token: store.state.settings.verifyToken)
                            if let data = MarkFactory.pdfData(payload: payload) {
                                printData = data
                                showPrint = true
                            }
                        }
                        ProfileRow(icon: "square.and.arrow.up", label: "Share PDF", showBorder: true) {
                            let payload = QR.buildPayload(token: store.state.settings.verifyToken)
                            if let data = MarkFactory.pdfData(payload: payload) {
                                let url = FileManager.default.temporaryDirectory.appendingPathComponent("qiyama-mark.pdf")
                                try? data.write(to: url)
                                shareItems = [url]
                                showShare = true
                            }
                        }
                        ProfileRow(icon: "camera", label: "Adopt printed mark", showBorder: true) {
                            showAdoptScan = true
                        }
                        ProfileRow(icon: "viewfinder", label: "Test scan", showBorder: true) {
                            showTestScan = true
                        }
                        ProfileRow(icon: "arrow.triangle.2.circlepath", label: "Replace mark", destructive: true, showBorder: false) {
                            showReplaceConfirm = true
                        }
                    }

                    sectionCard(title: "Program") {
                        ProfileRow(
                            icon: "calendar",
                            label: "Length",
                            value: "\(store.state.settings.programLengthDays) days",
                            showBorder: true
                        )
                        ProfileRow(
                            icon: "arrow.counterclockwise",
                            label: "Restart onboarding",
                            destructive: true,
                            showBorder: false
                        ) {
                            showRestartConfirm = true
                        }
                    }

                    sectionCard(title: "About") {
                        ProfileRow(
                            icon: "info.circle",
                            label: "Version",
                            value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—",
                            showBorder: false
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .background(QiyamaTheme.paper.ignoresSafeArea())
            .navigationDestination(for: ProfileRoute.self) { route in
                switch route {
                case .location:
                    ProfileLocationView()
                case .offset:
                    ProfileOffsetView()
                case .calculation:
                    ProfileCalculationView()
                }
            }
        }
        .confirmationDialog("Replace mark?", isPresented: $showReplaceConfirm, titleVisibility: .visible) {
            Button("Replace", role: .destructive) {
                Task { await store.regenerateVerifyToken() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Old prints will stop working.")
        }
        .confirmationDialog("Restart onboarding?", isPresented: $showRestartConfirm, titleVisibility: .visible) {
            Button("Restart", role: .destructive) {
                store.restartOnboarding()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Clears mornings and progress on this phone. Your mark token is kept.")
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(items: shareItems)
        }
        .sheet(isPresented: $showTestScan) {
            TestScanView()
        }
        .sheet(isPresented: $showAdoptScan) {
            AdoptMarkScanView()
        }
        .background {
            if showPrint, let printData {
                PrintMarkView(data: printData)
                    .frame(width: 0, height: 0)
                    .onAppear { showPrint = false }
            }
        }
    }

    private var profileHeader: some View {
        let settings = store.state.settings
        let progress = store.state.progress
        return HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(QiyamaTheme.lantern.opacity(0.18))
                    .frame(width: 52, height: 52)
                Text("ق")
                    .font(QiyamaTheme.display(22, weight: .semibold))
                    .foregroundStyle(QiyamaTheme.lantern)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(progress.phase.label)
                    .font(QiyamaTheme.body(18, weight: .semibold))
                    .foregroundStyle(QiyamaTheme.ink)
                Text(settings.locationLabel)
                    .font(QiyamaTheme.body(13))
                    .foregroundStyle(QiyamaTheme.slate)
                    .lineLimit(1)
                Text("\(settings.offsetMinutes) min before Fajr")
                    .font(QiyamaTheme.body(13))
                    .foregroundStyle(QiyamaTheme.slate)
                    .monospacedDigit()
            }
            Spacer(minLength: 0)
        }
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(QiyamaTheme.body(18, weight: .semibold))
                .foregroundStyle(QiyamaTheme.ink)
            VStack(spacing: 0) {
                content()
            }
            .background(Color.white.opacity(0.45))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(QiyamaTheme.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

private enum ProfileRoute: Hashable {
    case location, offset, calculation
}

private struct ProfileRow: View {
    let icon: String
    let label: String
    var value: String? = nil
    var destructive: Bool = false
    var showBorder: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        let row = HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(destructive ? QiyamaTheme.miss : QiyamaTheme.lantern)
                .frame(width: 22)
            Text(label)
                .font(QiyamaTheme.body(15, weight: .medium))
                .foregroundStyle(destructive ? QiyamaTheme.miss : QiyamaTheme.ink)
            Spacer(minLength: 8)
            if let value {
                Text(value)
                    .font(QiyamaTheme.body(14))
                    .foregroundStyle(QiyamaTheme.slate)
                    .lineLimit(1)
            }
            if action != nil, !destructive {
                Text("›")
                    .font(QiyamaTheme.body(20, weight: .semibold))
                    .foregroundStyle(QiyamaTheme.slate)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            if showBorder {
                Rectangle().fill(QiyamaTheme.line).frame(height: 1).padding(.leading, 50)
            }
        }

        if let action {
            Button(action: action) { row }
                .buttonStyle(.plain)
        } else {
            row
        }
    }
}

struct ProfileLocationView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var selection: LocationChoice?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Where are you praying?")
                    .font(QiyamaTheme.display(28, weight: .semibold))
                    .foregroundStyle(QiyamaTheme.ink)
                Text("Fajr is calculated for this place.")
                    .font(QiyamaTheme.body(15))
                    .foregroundStyle(QiyamaTheme.slate)

                CitySearchField(selection: $selection, autofocus: true)
            }
            .padding(20)
        }
        .background(QiyamaTheme.paper.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        guard let selection else { return }
                        await store.setLocation(selection)
                        dismiss()
                    }
                }
                .disabled(selection == nil)
                .fontWeight(.semibold)
            }
        }
        .onAppear {
            let s = store.state.settings
            selection = LocationChoice(
                id: s.locationId,
                label: s.locationLabel,
                latitude: s.latitude,
                longitude: s.longitude,
                timeZone: s.timeZone
            )
        }
    }
}

struct ProfileOffsetView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var offset = OffsetMinutes.default
    @State private var wakeText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Wake before Fajr")
                    .font(QiyamaTheme.display(28, weight: .semibold))
                    .foregroundStyle(QiyamaTheme.ink)

                OffsetControl(minutes: $offset)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Tonight this rings at")
                        .font(QiyamaTheme.body(13))
                        .foregroundStyle(QiyamaTheme.slate)
                    Text(wakeText)
                        .font(QiyamaTheme.display(40, weight: .semibold))
                        .foregroundStyle(QiyamaTheme.lantern)
                        .monospacedDigit()
                }
            }
            .padding(20)
        }
        .background(QiyamaTheme.paper.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        await store.setOffset(offset)
                        dismiss()
                    }
                }
                .fontWeight(.semibold)
            }
        }
        .onAppear {
            offset = OffsetMinutes.clamp(store.state.settings.offsetMinutes)
            refreshWake()
        }
        .onChange(of: offset) { _, _ in refreshWake() }
    }

    private func refreshWake() {
        let s = store.state.settings
        let next = Prayer.nextFajr(latitude: s.latitude, longitude: s.longitude, method: s.calculationMethod)
        let wake = Schedule.wakeFromFajr(next.fajr, offsetMinutes: offset)
        wakeText = Schedule.formatTime(wake, timeZone: s.timeZone)
    }
}

struct ProfileCalculationView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Calculation")
                    .font(QiyamaTheme.display(28, weight: .semibold))
                    .foregroundStyle(QiyamaTheme.ink)
                    .padding(.bottom, 8)

                ForEach(CalculationMethodId.allCases) { method in
                    Button {
                        Task { await store.updateSettings { $0.calculationMethod = method } }
                    } label: {
                        HStack {
                            Text(method.label)
                                .font(QiyamaTheme.body(16))
                                .foregroundStyle(QiyamaTheme.ink)
                            Spacer()
                            if store.state.settings.calculationMethod == method {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(QiyamaTheme.lantern)
                            }
                        }
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    Rectangle().fill(QiyamaTheme.line).frame(height: 1)
                }

                Text("Default is ISNA for North America.")
                    .font(QiyamaTheme.body(13))
                    .foregroundStyle(QiyamaTheme.slate)
                    .padding(.top, 12)
            }
            .padding(20)
        }
        .background(QiyamaTheme.paper.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TestScanView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var message = "Point at your mark."

    var body: some View {
        NavigationStack {
            QRScannerView(
                validate: { QR.isValidScan($0, token: store.state.settings.verifyToken) },
                onAccepted: { _ in
                    message = "Mark matched."
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { dismiss() }
                },
                onRejected: {
                    message = "Not your mark."
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            )
            .ignoresSafeArea()
            .overlay(alignment: .bottom) {
                Text(message)
                    .font(QiyamaTheme.body(15))
                    .foregroundStyle(QiyamaTheme.wakeText)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(QiyamaTheme.wake.opacity(0.85))
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct AdoptMarkScanView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var message = "Scan the mark you already printed."

    var body: some View {
        NavigationStack {
            QRScannerView(
                validate: { QR.parseToken(from: $0) != nil },
                onAccepted: { code in
                    Task {
                        let ok = await store.adoptPrintedMark(fromScan: code)
                        if ok {
                            message = "Adopted. This print works now."
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            try? await Task.sleep(for: .milliseconds(700))
                            dismiss()
                        } else {
                            message = "Couldn’t read that code."
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                        }
                    }
                },
                onRejected: {
                    message = "Need a Qiyama mark (qiyama-verify:…)."
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            )
            .ignoresSafeArea()
            .overlay(alignment: .bottom) {
                Text(message)
                    .font(QiyamaTheme.body(15))
                    .foregroundStyle(QiyamaTheme.wakeText)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(QiyamaTheme.wake.opacity(0.85))
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .navigationTitle("Adopt mark")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

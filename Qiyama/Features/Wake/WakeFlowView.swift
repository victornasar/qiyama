import SwiftUI

struct WakeFlowView: View {
    @Environment(AppStore.self) private var store
    @State private var showConfirm = false

    var body: some View {
        Group {
            if showConfirm {
                ConfirmView(onDone: { showConfirm = false })
            } else {
                WakeView(onScannedOrConfirmed: { showConfirm = true })
            }
        }
        .interactiveDismissDisabled()
    }
}

struct WakeView: View {
    @Environment(AppStore.self) private var store
    var onScannedOrConfirmed: () -> Void

    @State private var scanHint = "Point at your mark."
    @State private var keepAudioAlive = true

    private var dateKey: String {
        store.state.interventionActiveDateKey ?? store.tonight.dateKey
    }

    private var needsScan: Bool {
        Progression.requiresPhysicalProof(store.state.progress.assistanceLevel)
    }

    private var canBail: Bool {
        store.state.practiceActive || store.state.progress.assistanceLevel <= 1
    }

    var body: some View {
        ZStack {
            QiyamaTheme.wake.ignoresSafeArea()

            VStack(spacing: 0) {
                Text(needsScan ? "Walk to your mark." : "Get up.")
                    .font(QiyamaTheme.display(28, weight: .medium))
                    .foregroundStyle(QiyamaTheme.wakeText)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                    .padding(.horizontal, 20)

                if needsScan {
                    // Fitts: scanner is the primary target — max area, short distance from eye/hand.
                    QRScannerView(
                        validate: { QR.isValidScan($0, token: store.state.settings.verifyToken) },
                        onAccepted: { _ in completeProof() },
                        onRejected: {
                            scanHint = "Not your mark."
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 16)

                    Text(scanHint)
                        .font(QiyamaTheme.body(14))
                        .foregroundStyle(QiyamaTheme.wakeText.opacity(0.55))
                        .padding(.vertical, 12)
                } else {
                    Spacer()
                    Button {
                        completeProof()
                    } label: {
                        Text("I'm out of bed")
                            .font(QiyamaTheme.body(18, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .foregroundStyle(QiyamaTheme.wake)
                            .background(QiyamaTheme.lantern)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    Spacer()
                }

                if let err = WakeAudioController.shared.lastError {
                    Text("Audio error: \(err)")
                        .font(QiyamaTheme.body(12))
                        .foregroundStyle(QiyamaTheme.miss)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }

                // Bail: small, low, distant from primary action (Fitts inverse).
                if canBail {
                    Button {
                        keepAudioAlive = false
                        if store.state.practiceActive {
                            store.endPractice()
                        } else {
                            store.markMissed(dateKey: dateKey)
                        }
                    } label: {
                        Text(store.state.practiceActive ? "End practice" : "Not tonight")
                            .font(QiyamaTheme.body(13))
                            .foregroundStyle(QiyamaTheme.wakeText.opacity(0.4))
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 12)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            keepAudioAlive = true
            WakeAudioController.shared.start()
        }
        .task {
            try? await Task.sleep(for: .milliseconds(600))
            guard keepAudioAlive else { return }
            WakeAudioController.shared.reassert()
        }
    }

    private func completeProof() {
        keepAudioAlive = false
        store.silenceActiveAlarm()
        WakeAudioController.shared.stop()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        if !store.state.practiceActive {
            store.markOutOfBed(dateKey: dateKey)
        }
        onScannedOrConfirmed()
    }
}

struct ConfirmView: View {
    @Environment(AppStore.self) private var store
    var onDone: () -> Void

    private var dateKey: String {
        store.state.interventionActiveDateKey ?? store.tonight.dateKey
    }

    var body: some View {
        ZStack {
            QiyamaTheme.wake.ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                if store.state.practiceActive {
                    Text("Practice complete.")
                        .font(QiyamaTheme.display(30, weight: .medium))
                        .foregroundStyle(QiyamaTheme.wakeText)
                    Text("Mark scan worked. Nothing was logged.")
                        .font(QiyamaTheme.body(15))
                        .foregroundStyle(QiyamaTheme.wakeText.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Button {
                        store.endPractice()
                        onDone()
                    } label: {
                        Text("Done")
                            .font(QiyamaTheme.body(18, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .foregroundStyle(QiyamaTheme.wake)
                            .background(QiyamaTheme.lantern)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                } else {
                    Text("You got up.")
                        .font(QiyamaTheme.display(30, weight: .medium))
                        .foregroundStyle(QiyamaTheme.wakeText)
                    Text("That’s the job. Tahajjud is yours now.")
                        .font(QiyamaTheme.body(16))
                        .foregroundStyle(QiyamaTheme.wakeText.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)

                    Button {
                        store.clearIntervention()
                        onDone()
                    } label: {
                        Text("Done")
                            .font(QiyamaTheme.body(18, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .foregroundStyle(QiyamaTheme.wake)
                            .background(QiyamaTheme.lantern)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                }
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            WakeAudioController.shared.stop()
        }
    }
}

import SwiftUI

struct ContentView: View {
    @State private var audio = WakeAudioController.shared

    var body: some View {
        NavigationStack {
            List {
                Section("State") {
                    LabeledContent("Running", value: audio.isRunning ? "yes" : "no")
                    LabeledContent("Playing", value: audio.isPlaying ? "yes" : "no")
                    LabeledContent(
                        "Volume",
                        value: String(format: "%.0f%% of max", (audio.currentVolume / WakeAudioController.volumeMax) * 100)
                    )
                    ProgressView(value: Double(audio.currentVolume), total: Double(WakeAudioController.volumeMax))
                }

                Section("Controls") {
                    Button("Start forest alarm") {
                        audio.start()
                    }
                    .disabled(audio.isRunning)

                    Button("Stop (simulate scan)", role: .destructive) {
                        audio.stop()
                    }
                    .disabled(!audio.isRunning && !audio.isPlaying)
                }

                Section("Device checklist") {
                    Text(
                        """
                        1. Start forest alarm — volume should ramp ~60s to 50%.
                        2. Lock the phone — audio should continue (background mode).
                        3. Confirm no Pause on lock-screen Now Playing (or ignore if absent).
                        4. Trigger an interruption (Siri, phone call, another app’s audio) — after it ends, forest should auto-resume without opening the app.
                        5. Stop = intentional (QR path). Force-quit / hardware volume still win; that is expected.
                        """
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }

                if let err = audio.lastError {
                    Section("Last error") {
                        Text(err)
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button("Clear log") { audio.clearLog() }
                    ForEach(Array(audio.logLines.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(.caption2, design: .monospaced))
                    }
                } header: {
                    Text("Log")
                }
            }
            .navigationTitle("AVAudioSession Spike")
        }
    }
}

#Preview {
    ContentView()
}

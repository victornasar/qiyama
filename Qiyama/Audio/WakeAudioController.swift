import AudioToolbox
import AVFoundation
import Foundation
import MediaPlayer
import UIKit

/// Native wake audio: exclusive playback session, no Now Playing controls,
/// interruption / route-change auto-resume.
/// Soft wake: hardware volume pinned, player ramps 0% → 100% of that pin (~25% absolute).
///
/// This whole controller is a supplemental layer, not the wake guarantee — see WakeAlarms.
/// The volume pin is enforced continuously (KVO on outputVolume + watchdog backstop), but
/// it's a UIKit trick (a hidden MPVolumeView slider) and iOS mostly stops honoring
/// programmatic slider changes once the screen locks. There is no public API for a
/// backgrounded app to force its own media output volume — so if the phone reaches 0 while
/// locked, the forest goes silent, full stop, and no amount of KVO/audio-session cleverness
/// changes that. The Taptic Engine isn't gated by the volume slider at all, so silence below
/// `silenceThreshold` engages a repeating vibration instead. Treat both as best-effort: the
/// thing that's actually supposed to survive a silenced, locked phone is the AlarmKit alarm
/// in WakeAlarms, which plays through the system alert channel instead of this one.
@MainActor
@Observable
final class WakeAudioController: NSObject {
    static let shared = WakeAudioController()

    /// Absolute ceiling as a fraction of full device volume.
    static let hardwareVolumeTarget: Float = 0.13
    /// Player starts silent and eases up to full relative volume (of the pin above).
    static let volumeFloor: Float = 0
    static let volumeMax: Float = 1.0
    static let rampSeconds: TimeInterval = 60
    /// Below this, treat the device as silenced and switch to the vibration fallback.
    static let silenceThreshold: Float = 0.02
    static let vibrationInterval: TimeInterval = 1.2

    private(set) var isRunning = false
    private(set) var isPlaying = false
    private(set) var currentVolume: Float = 0
    private(set) var logLines: [String] = []
    private(set) var lastError: String?

    private var player: AVAudioPlayer?
    private var rampTimer: Timer?
    private var watchdog: Timer?
    private var rampStartedAt: Date?
    private var allowStop = false
    private var observersInstalled = false
    private var savedHardwareVolume: Float?
    private var volumeHostView: MPVolumeView?
    private var outputVolumeObservation: NSKeyValueObservation?
    private var vibrationTimer: Timer?
    private var vibrationActive = false

    override private init() {
        super.init()
    }

    // MARK: - Public

    func start() {
        if isRunning {
            enforcePlayback()
            return
        }

        allowStop = false
        isRunning = true
        rampStartedAt = Date()
        lastError = nil

        do {
            try activateSession()
            try preparePlayer()
            installObserversIfNeeded()
            suppressNowPlayingControls()
            pinHardwareVolumeForSoftWake()
            UIApplication.shared.isIdleTimerDisabled = true

            player?.volume = Self.volumeFloor
            currentVolume = Self.volumeFloor
            player?.currentTime = 0
            guard player?.play() == true else {
                throw WakeAudioError.playFailed
            }
            isPlaying = player?.isPlaying ?? false

            startRamp()
            startWatchdog()
            log("start — soft wake 0→\(Self.hardwareVolumeTarget) over \(Int(Self.rampSeconds))s")
        } catch {
            isRunning = false
            lastError = String(describing: error)
            log("start FAILED: \(error)")
        }
    }

    /// Call after camera / other session grabs focus.
    func reassert() {
        guard isRunning, !allowStop else { return }
        resumeAfterSystemEvent(reason: "reassert")
    }

    /// Call after QR scan / intentional dismiss.
    func stop() {
        allowStop = true
        isRunning = false
        clearTimers()
        player?.stop()
        player?.currentTime = 0
        isPlaying = false
        currentVolume = 0
        UIApplication.shared.isIdleTimerDisabled = false
        restoreHardwareVolume()
        deactivateSessionQuietly()
        log("stop — intentional")
    }

    func clearLog() {
        logLines = []
    }

    // MARK: - Session

    private func activateSession() throws {
        let session = AVAudioSession.sharedInstance()
        // Exclusive playback: silent switch ignored, do not mix with others.
        // Personal sideload: fight for focus; interruption handler resumes if OS pauses us.
        try session.setCategory(
            .playback,
            mode: .default,
            options: [.duckOthers]
        )
        try session.setActive(true, options: [])
        log("session category=.playback options=.duckOthers active=true")
    }

    private func deactivateSessionQuietly() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            log("deactivate note: \(error)")
        }
    }

    private func preparePlayer() throws {
        let url =
            Bundle.main.url(forResource: "forest-ambiance", withExtension: "mp3")
            ?? Bundle.main.url(forResource: "forest-ambiance", withExtension: "mp3", subdirectory: "Sounds")
        guard let url else {
            throw WakeAudioError.missingSoundFile
        }
        if player == nil {
            let p = try AVAudioPlayer(contentsOf: url)
            p.delegate = self
            p.numberOfLoops = 0 // one pass (~5 min), same as Expo
            p.prepareToPlay()
            player = p
            log("loaded \(url.lastPathComponent)")
        }
    }

    /// Do not publish Now Playing — lock-screen pause was a dismiss path in Expo.
    private func suppressNowPlayingControls() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        let center = MPRemoteCommandCenter.shared()
        for command in [
            center.playCommand,
            center.pauseCommand,
            center.stopCommand,
            center.togglePlayPauseCommand,
            center.nextTrackCommand,
            center.previousTrackCommand,
            center.changePlaybackPositionCommand,
        ] {
            command.isEnabled = false
            command.removeTarget(nil)
        }
    }

    // MARK: - Observers

    private func installObserversIfNeeded() {
        guard !observersInstalled else { return }
        observersInstalled = true
        let nc = NotificationCenter.default

        nc.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
        nc.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
        nc.addObserver(
            self,
            selector: #selector(handleMediaServicesReset(_:)),
            name: AVAudioSession.mediaServicesWereResetNotification,
            object: AVAudioSession.sharedInstance()
        )

        // Hardware volume buttons / Control Center are the one bypass a hidden slider
        // can't preempt — catch the change after the fact and snap it straight back.
        outputVolumeObservation = AVAudioSession.sharedInstance().observe(
            \.outputVolume,
            options: [.new]
        ) { [weak self] _, _ in
            Task { @MainActor in
                self?.enforceHardwareVolumeLock()
            }
        }
    }

    private func enforceHardwareVolumeLock() {
        guard isRunning, !allowStop else { return }
        setHardwareVolume(Self.hardwareVolumeTarget)
        updateVibrationFallback()
        log("hardware volume tamper — re-pinned to \(Self.hardwareVolumeTarget)")
    }

    @objc private func handleInterruption(_ note: Notification) {
        guard isRunning, !allowStop else { return }
        guard let info = note.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
        case .began:
            log("interruption BEGAN")
            isPlaying = false
        case .ended:
            let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            log("interruption ENDED shouldResume=\(options.contains(.shouldResume))")
            // Resume even if shouldResume is false — personal alarm: we want the forest back.
            resumeAfterSystemEvent(reason: "interruptionEnded")
        @unknown default:
            log("interruption unknown type")
        }
    }

    @objc private func handleRouteChange(_ note: Notification) {
        guard isRunning, !allowStop else { return }
        guard let info = note.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue)
        else { return }

        log("routeChange reason=\(reason.rawValue)")
        switch reason {
        case .oldDeviceUnavailable, .categoryChange, .override:
            resumeAfterSystemEvent(reason: "routeChange")
        default:
            break
        }
    }

    @objc private func handleMediaServicesReset(_ note: Notification) {
        guard isRunning, !allowStop else { return }
        log("mediaServicesWereReset — rebuilding player")
        player = nil
        resumeAfterSystemEvent(reason: "mediaReset")
    }

    private func resumeAfterSystemEvent(reason: String) {
        do {
            try activateSession()
            if player == nil {
                try preparePlayer()
            }
            suppressNowPlayingControls()
            enforcePlayback()
            log("auto-resume OK (\(reason))")
        } catch {
            lastError = String(describing: error)
            log("auto-resume FAILED (\(reason)): \(error)")
        }
    }

    // MARK: - Ramp / watchdog

    private func startRamp() {
        rampTimer?.invalidate()
        rampTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickRamp()
            }
        }
    }

    private func startWatchdog() {
        watchdog?.invalidate()
        watchdog = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.enforcePlayback()
            }
        }
    }

    private func tickRamp() {
        guard isRunning, let start = rampStartedAt, let player else { return }
        let t = min(1, Date().timeIntervalSince(start) / Self.rampSeconds)
        // Ease-in from silence — quiet first minutes, still gentle at the top.
        let span = Self.volumeMax - Self.volumeFloor
        let volume = Self.volumeFloor + span * Float(t * t)
        player.volume = volume
        currentVolume = volume
        if t >= 1 {
            rampTimer?.invalidate()
            rampTimer = nil
        }
    }

    private func enforcePlayback() {
        guard isRunning, !allowStop, let player else { return }
        setHardwareVolume(Self.hardwareVolumeTarget)
        updateVibrationFallback()
        if player.volume < currentVolume {
            player.volume = currentVolume
        }
        if !player.isPlaying {
            do {
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                log("watchdog setActive: \(error)")
            }
            player.play()
            log("watchdog forced play")
        }
        isPlaying = player.isPlaying
    }

    private func clearTimers() {
        rampTimer?.invalidate()
        rampTimer = nil
        watchdog?.invalidate()
        watchdog = nil
        vibrationTimer?.invalidate()
        vibrationTimer = nil
        vibrationActive = false
    }

    /// Volume-slider tampering doesn't reach the Taptic Engine — buzz on a loop for as
    /// long as the device reads silent, stand down the moment audio is audible again.
    private func updateVibrationFallback() {
        let silenced = AVAudioSession.sharedInstance().outputVolume <= Self.silenceThreshold
        if silenced, !vibrationActive {
            vibrationActive = true
            log("output silenced — vibration fallback engaged")
            vibrationTimer?.invalidate()
            let timer = Timer.scheduledTimer(withTimeInterval: Self.vibrationInterval, repeats: true) { _ in
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
            vibrationTimer = timer
            timer.fire()
        } else if !silenced, vibrationActive {
            vibrationActive = false
            vibrationTimer?.invalidate()
            vibrationTimer = nil
            log("output audible again — vibration fallback stood down")
        }
    }

    // MARK: - Hardware volume pin

    /// AVAudioPlayer.volume is relative to the ringer/media slider.
    /// Pin hardware to ~25% so the ramp is the same every morning.
    private func pinHardwareVolumeForSoftWake() {
        let session = AVAudioSession.sharedInstance()
        savedHardwareVolume = session.outputVolume
        setHardwareVolume(Self.hardwareVolumeTarget)
        log("hardware volume \(savedHardwareVolume ?? -1) → \(Self.hardwareVolumeTarget)")
    }

    private func restoreHardwareVolume() {
        if let saved = savedHardwareVolume {
            setHardwareVolume(saved)
            log("hardware volume restored → \(saved)")
        }
        savedHardwareVolume = nil
        volumeHostView?.removeFromSuperview()
        volumeHostView = nil
    }

    private func setHardwareVolume(_ value: Float) {
        let clamped = max(0, min(1, value))
        // Hidden MPVolumeView slider is the supported way to set system media volume.
        let host: MPVolumeView
        if let existing = volumeHostView {
            host = existing
        } else {
            let view = MPVolumeView(frame: CGRect(x: -2000, y: -2000, width: 1, height: 1))
            view.alpha = 0.01
            view.isUserInteractionEnabled = false
            if let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)
            {
                window.addSubview(view)
            }
            volumeHostView = view
            host = view
        }

        // Slider may not exist until the next runloop after hierarchy attach.
        DispatchQueue.main.async {
            guard let slider = host.subviews.compactMap({ $0 as? UISlider }).first else {
                self.log("volume slider missing — player-relative only")
                return
            }
            if abs(slider.value - clamped) > 0.01 {
                slider.value = clamped
            }
        }
    }

    private func log(_ message: String) {
        let stamp = Date().formatted(date: .omitted, time: .standard)
        logLines.insert("[\(stamp)] \(message)", at: 0)
        if logLines.count > 100 {
            logLines = Array(logLines.prefix(100))
        }
    }
}

extension WakeAudioController: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.isRunning = false
            self.clearTimers()
            UIApplication.shared.isIdleTimerDisabled = false
            self.restoreHardwareVolume()
            self.deactivateSessionQuietly()
            self.log("finished playing successfully=\(flag)")
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            self.lastError = error.map(String.init(describing:)) ?? "decode error"
            self.log("decode error: \(String(describing: error))")
        }
    }
}

enum WakeAudioError: Error {
    case missingSoundFile
    case playFailed
}

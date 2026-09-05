# AVAudioSession Spike — FINDINGS

Goal: native layer that keeps the forest alarm alive through lock-screen and audio interruptions, until intentional stop (QR / scan). Complements AlarmKit (wake trigger) — this is the sticky in-app audio.

**Status:** scaffold builds against iOS 26.5 SDK. Device checklist below is the real proof.

## Design choices (personal sideload)

| Choice | Why |
|---|---|
| `AVAudioSessionCategory.playback` + `.duckOthers` | Silent switch ignored; claim focus aggressively. |
| `UIBackgroundModes: audio` | Keep playing when locked / backgrounded. |
| `AVAudioSessionInterruptionNotification` → auto-resume | Don’t rely on JS polling; resume even if `shouldResume` is false (alarm intent). |
| Route change + media services reset handlers | Headphones unplug / audio daemon restart. |
| No `MPNowPlayingInfoCenter` + remote commands disabled | Lock-screen Pause was a dismiss path in Expo. |
| Ramp 0→50% over 60s, quadratic | Same as Expo `wakeAlarmController`. |
| One pass through `forest-ambiance.mp3` (~5 min) | Not infinite loop; stop early on scan. |
| Watchdog 0.5s | Belt if something pauses without a notification. |
| Idle timer disabled while running | Screen can stay available for scan UI later. |

## Still impossible on iOS

- Force-quit kills the process → audio dies.  
- Hardware volume can mute.  
- Not Clock.app; overnight kill needs AlarmKit and/or a real Clock alarm as the trigger.

## Device checklist

Date / OS: ________  

| Test | Pass? | Notes |
|---|---|---|
| Ramp audible over ~60s | ☐ | |
| Continues when locked | ☐ | |
| No Pause on lock screen / Now Playing absent | ☐ | |
| Siri interruption → auto-resume | ☐ | |
| Phone call end → auto-resume | ☐ | |
| Another app grabs audio → resume after | ☐ | |
| Stop button ends cleanly | ☐ | |
| Force-quit stops audio (expected) | ☐ | |

## Relationship to AlarmKit spike

```
AlarmKit (or Clock.app)  →  gets you to pick up the phone
AVAudioSession module    →  holds forest until QR scan
```

Port `WakeAudioController.swift` into the real native Qiyama app once both spikes pass on device.

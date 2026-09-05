# AVAudioSession Spike

Native wake-audio module for Qiyama: exclusive `AVAudioSession`, background audio, interruption auto-resume, forest ramp — no Now Playing pause controls.

## Open / run

```bash
cd spikes/AVAudioSessionSpike
xcodegen generate
open AVAudioSessionSpike.xcodeproj
```

Run on a **physical iPhone** (simulator won’t prove lock-screen / interruption behavior).

Bundle id: `com.qiyama.avaudiosessionspike`.

## What to verify

1. Start → volume ramps softly over ~60s  
2. Lock phone → audio continues  
3. No usable lock-screen Pause (or no Now Playing card)  
4. Interrupt with Siri / a call / another app → forest **auto-resumes** when the interruption ends  
5. Stop = intentional dismiss (QR path)

See `FINDINGS.md`.

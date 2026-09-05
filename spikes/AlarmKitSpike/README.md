# AlarmKit Spike

Throwaway native iOS 26 app to answer one question for Qiyama:

> Can AlarmKit fire a real system alarm at a fixed time while the app is force-quit and the phone is locked?

## Open / run

```bash
cd spikes/AlarmKitSpike
xcodegen generate
open AlarmKitSpike.xcodeproj
```

Or build from CLI:

```bash
xcodegen generate
xcodebuild -scheme AlarmKitSpike -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

Bundle id: `com.qiyama.alarmkitspike`.

## Before it can actually fire

1. Confirm `NSAlarmKitUsageDescription` is in `Info.plist` (already set).  
2. Run on device → **Request authorization** → allow the system prompt.  
3. Schedule Fixed / Timer and test force-quit + lock.

There is **no** AlarmKit toggle in Certificates, Identifiers & Profiles. Apple’s docs only require the plist key + user auth (plus a widget extension if you use countdown UI). See `FINDINGS.md`.

## In-app buttons

- **Request authorization**
- **Timer in 45s** — quick fire while watching
- **Fixed date in 90s** — then force-quit + lock (the real test)
- **Relative +2 min**
- **Cancel all**

See `FINDINGS.md` for the decision tree and checklist.

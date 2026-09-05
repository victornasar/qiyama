# AlarmKit Spike — FINDINGS

Personal Qiyama spike: does AlarmKit give “fires at exact time from killed / locked” close enough to Clock.app?

**Status:** scaffold **builds successfully** against Xcode / iPhoneOS 26.5 SDK (`xcodebuild` simulator Debug). Device behavior TBD until you run the checklist below (and until the entitlement is granted).

## What we already know from the SDK + docs (no device needed)

| Question | Answer |
|---|---|
| API exists on this machine? | Yes — `AlarmKit.framework` in iPhoneOS 26.5 SDK; `AlarmManager.shared`, `schedule`, `requestAuthorization`. |
| Breaks Silent / Focus? | Designed to — same class of alert as Clock alarms (WWDC25). |
| Survives killed app? | That is the claim; **verify on device** with Fixed + force-quit. |
| Scan-to-dismiss? | **No.** System Stop / Snooze still ends the alert. AlarmKit wakes you; Qiyama still owns the sticky post-wake layer. |
| Custom forest ramp as the alarm sound? | Limited — `AlertSound` is ActivityKit’s alert sound (bundle / Library/Sounds name or `.default`), not a long AVAudioSession ramp. Forest ramp still belongs in-app after open. |
| Personal sideload skips App Review? | Yes for shipping pressure. **Does not skip the AlarmKit entitlement.** |

## Auth / “entitlement” — corrected

**Apple’s official AlarmKit docs do not require a Developer Portal entitlement.** What they require:

1. `NSAlarmKitUsageDescription` in Info.plist (missing → cannot schedule)
2. User authorization via `AlarmManager.requestAuthorization()` (or auto-prompt on first schedule)
3. A **Widget Extension** if you use countdown presentation (otherwise system may dismiss alarms)

This spike already builds and codesigns with **no** AlarmKit key in the entitlements plist (only team id + `get-task-allow`). You will not find “AlarmKit” under Certificates, Identifiers & Profiles — that matches Reddit reports.

Third-party blogs that say “apply for AlarmKit entitlement” appear overstated or outdated relative to WWDC25 / Apple sample docs. A `/contact/request/alarmkit` URL exists, but it is **not** documented as a required setup step.

**Xcode error 70** is usually a **provisioning / codesign** failure (profile vs capabilities mismatch), not “Apple denied AlarmKit.” Fix: remove phantom capabilities you added, clean signing, regenerate automatic profile — don’t hunt for a portal AlarmKit toggle.

**Runtime** failures (auth denied, schedule throws) are separate: user denied the prompt, missing plist key, or countdown without a Live Activity widget.

## Device checklist (fill in when you run it)

Date / OS: ________  
Auth prompt appeared? ☐  
Auth state after grant: ________  
NSAlarmKitUsageDescription present? ☐ (yes in this spike)  

| Test | Pass? | Notes |
|---|---|---|
| Timer 45s, app foreground | ☐ | |
| Timer 45s, app background | ☐ | |
| Fixed 90s, force-quit, locked, Silent on | ☐ | **deciding test** |
| Relative +2 min | ☐ | |
| Focus / Sleep Focus still breaks through? | ☐ | |
| Can user Stop without opening app? | ☐ (expect yes) | |

## Decision tree for Qiyama

```
Fixed schedule fires from killed/locked after user grants AlarmKit auth?
  YES → Native Qiyama with AlarmKit as wake trigger
         + in-app AVAudioSession forest + QR dismiss as the sticky layer
         + optional Clock.app still as belt-and-suspenders
  NO  → Native AVAudioSession + interruption auto-resume
         + keep Clock.app as the reliable trigger
```

## API surface used in this spike

- `AlarmManager.requestAuthorization()` / `.authorizationState`
- `.timer(duration:attributes:sound:)` — short latency lab test
- `.fixed(Date)` — absolute fire (overnight / killed)
- `.alarm(schedule: .relative(...))` — clock-of-day style
- `AlarmPresentation.Alert` + `AlarmButton` stop control
- `NSAlarmKitUsageDescription` in Info.plist

## Limits that stay true even if AlarmKit is perfect

- Hardware volume buttons / force-quit of the *alarming session* still have system behavior you don’t own.
- System alarm UI can stop the alert without your QR scan — belt-and-suspenders with Clock or accept Stop as “got me out of bed,” then open Qiyama for mark/scan.
- You still want aggressive `AVAudioSession` after the user is in-app for forest + scan-to-release.

# Qiyama

Native SwiftUI iOS app. Train yourself to get out of bed for Tahajjud, then wean off the app.

## Open

```bash
xcodegen generate
open Qiyama.xcodeproj
```

In Xcode, set your **Signing Team**. Team ID is not stored in this repo.

Or install without Xcode’s debugger (skips shared-cache symbol copy):

```bash
cp scripts/run-native.local.sh.example scripts/run-native.local.sh
# fill in DEVELOPMENT_TEAM + device IDs
./scripts/run-native.sh
```

Bundle id: `app.qiyama.train`

## Layout

- `Qiyama/` — Swift source
- `Qiyama.xcodeproj` / `project.yml` — XcodeGen
- `DESIGN.md` — visual direction
- `spikes/` — AlarmKit / AVAudioSession experiments
- `assets/` — icon source files

## Note on Xcode “Copying shared cache symbols”

Do not wait on it. Use `./scripts/run-native.sh` or open the app from the home screen. Symbols are only for breakpoints.

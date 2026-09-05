# Qiyama — Design Direction

## Product

Qiyama (قيام) means rising / standing. The app trains one behavior: get out of bed for Tahajjud, then gradually stop needing the app.

It is a temporary training system, not a permanent alarm clock and not a prayer-times utility.

## Audience & moment

Someone waking between roughly 3:00–5:30 AM in a dark room, half-asleep, who has already failed at “just get up.” The UI must be readable at night, decisive, and short. Daytime screens (evening prep, progress) can be quieter and cooler.

## Personality

Quiet. Firm. Human. No coach energy. No streak theater. Honest about misses without shame. Speaks like a clear note left for yourself, not like a habit app.

## Visual identity

### Palette

Night-first, lantern-lit — not purple tech, not cream-and-terracotta wellness.

| Token | Hex | Role |
|-------|-----|------|
| `ink` | `#12151C` | Primary text; wake-screen field |
| `paper` | `#E8ECF1` | Daytime background (cool, not cream) |
| `slate` | `#3A4454` | Secondary text |
| `line` | `#C5CDD8` | Hairlines / dividers only |
| `lantern` | `#C4A35A` | Single accent: time emphasis, active tab, primary action |
| `wake` | `#0B0D12` | Intervention takeover background |
| `wakeText` | `#F0EDE6` | Intervention text |
| `miss` | `#8F4E4E` | Missed / setback — muted, not alarming red |
| `ok` | `#4F6F5C` | Confirmed out-of-bed / prayed |

One accent only (`lantern`). Do not multiply accent uses across icons, badges, and glows.

### Typography

- **Display / times:** Literata — soft serif for clock figures; the product’s visual signature is the large wake time.
- **UI / body:** Source Sans 3 — clear at small sizes, calm, not Inter/system default.

Time figures are the hero. Labels stay small and plain.

### Layout

- One job per screen.
- Home: Fajr → offset → wake time, stacked and obvious. No dashboard grid.
- Progress: phase, day count, consistency — not XP, badges, or leaderboards.
- History: a list of mornings with one binary outcome (out of bed / missed).
- Wake takeover: full-bleed dark field, one instruction, one action. No tabs.

Cards only when they contain a real control (e.g. offset slider). Prefer open layout and hairlines over nested rounded boxes.

### Motion

Minimal. Allowed:

1. Soft fade when entering the wake screen.
2. Brief haptic + confirm flash after successful QR scan.
3. Progress phase label change without bounce/celebration particles.

No floating orbs, no confetti, no continuous ambient animation.

### Iconography

Tab icons only (familiar bottom nav). No decorative icon rows. Prefer simple SF-style / Ionicons outlines already in Expo — not a Lucide-everywhere marketing set.

## Copy

- Extremely short. Prefer three words over a sentence.
- Ban: “Start your journey”, “You’ve got this”, “Unlock”, “Build better habits”, “Become your best self”.
- Misses: “Missed. Next is tomorrow.” — then the next wake time.
- Wake screen: “Walk to your mark.” / “Scan to prove you’re up.”
- After out-of-bed: “You got up.” — the product ends at leaving bed; Tahajjud is the reason, not the logged gate.

## Interaction principles

1. **Anti-Slop** — every technique needs a product reason.
2. **Jakob’s Law** — daytime app uses familiar bottom tabs, settings lists, permission sheets.
3. **Behavioral break** — only the wake experience may abandon familiar patterns (no tabs, hard to dismiss, physical proof).
4. **Weaning** — assistance level drops as consistency holds; the app should feel less necessary over time.

## Liveliness dials

- **ENERGY:** 2 — restrained; night clarity over pep.
- **RHYTHM:** 3 — large time figures vs quiet labels create contrast.
- **MOTION:** 1 — almost still; motion only marks state changes that matter.

## Non-goals

Generic habit dashboards, prayer-times browsers, gamified streaks as the product, decorative gradients, fake stats, AI-sounding encouragement.

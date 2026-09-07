# Qiyama — App Store listing copy

Paste these fields into App Store Connect. Character limits are noted. Replace anything in `[brackets]`.

---

## Identity

| Field | Limit | Copy |
|-------|-------|------|
| **Name** | 30 | Qiyama |
| **Subtitle** | 30 | Wake before Fajr. Walk to a mark. |
| **Bundle ID** | — | `app.qiyama.train` |
| **SKU** | — | `qiyama-ios` |
| **Primary category** | — | Lifestyle |
| **Secondary category** | — | Health & Fitness |
| **Content rights** | — | Does not contain third-party content |
| **Age rating** | — | 4+ (no unrestricted web, no mature themes) |

---

## Promotional text

**Limit:** 170 characters. Can change without a new binary.

```
Qiyama trains one morning: leave bed before Fajr, walk to a printed mark, scan it. Assistance drops as the habit holds — then you stop needing the app.
```

*(169 characters)*

---

## Description

**Limit:** 4,000 characters.

```
Qiyama (قيام) means rising. The app trains one behavior: get out of bed for Tahajjud, prove it, then slowly stop needing the app.

It is not a permanent alarm clock. It is not a prayer-times browser. It is temporary training for the hardest part of the morning — leaving the bed.

HOW IT WORKS

1. Set your city and how many minutes before Fajr you want to wake.
2. Print a mark (or adopt one you already have) and put it away from the bed.
3. At wake time, a system alarm rings even if the phone is locked or silent.
4. Walk to the mark. Scan it. That is the proof you got up.

Morning proof is physical. Snooze is not the product.

WHAT YOU GET

• Wake time tied to Fajr for your location
• System alarms and notifications (both required)
• A wake screen that asks you to walk and scan
• Soft forest sound while you get up
• Progress by phase — not streaks, XP, or badges
• A simple history of mornings: out of bed, or missed

Misses are honest. “Missed. Next is tomorrow.” Then the next wake time.

WHO IT IS FOR

Someone who has already failed at “just get up.” Quiet. Firm. No coach energy.

REQUIREMENTS

• iPhone on iOS 26 or later
• Permission for Alarms & Timers
• Permission for Notifications
• Camera access to scan your mark
• A printed mark somewhere you must walk to

Privacy: wake times, location for Fajr, and your mark token stay on your device. Qiyama does not create an account and does not sell your data.

Support: https://github.com/victornasar/qiyama/issues
```

---

## Keywords

**Limit:** 100 characters total. Comma-separated. No spaces after commas if you need room. Do not repeat the app name.

```
tahajjud,fajr,wake,alarm,muslim,prayer,qiyam,morning,discipline,habit,salah
```

*(78 characters)*

Alternate denser set if you want more coverage:

```
tahajjud,fajr,qiyam,wake,alarm,muslim,salah,suhoor,discipline,morning,prayer
```

---

## What’s New (1.0.0)

```
First release.

Wake before Fajr. Print or adopt a mark. Walk to it when the alarm rings. Scan to prove you’re up. Assistance drops as consistency holds.
```

---

## URLs

| Field | Required | Value |
|-------|----------|-------|
| **Privacy Policy URL** | Yes | `https://github.com/victornasar/qiyama/blob/main/PRIVACY.md` |
| **Support URL** | Yes | `https://github.com/victornasar/qiyama/issues` |
| **Marketing URL** | No | Leave blank |

**Marketing URL** — skip it. Apple does not require one.

**Support URL** — use the repo Issues page. Reviewers and users can open a ticket there. You do not need a custom domain.

**Privacy Policy URL** — also required. Use `PRIVACY.md` in this repo (see below). Commit and push it before you submit, so the GitHub link loads for App Review.

---

## App Review notes

Paste into **App Review Information → Notes**.

```
Qiyama is a Tahajjud wake-training app.

Demo path:
1. Complete onboarding (city, wake offset, allow Alarms + Notifications, print or adopt a mark).
2. Home shows tonight’s Fajr and wake time.
3. Profile → Test scan / Practice (if available) or wait for wake window to exercise the wake flow.
4. Wake proof requires scanning the printed QR mark away from the bed.

Permissions:
• Alarms & Timers — required; system AlarmKit wake that rings when locked/silent
• Notifications — required; wake reminder
• Camera — required; scan the mark to confirm out of bed

No login. No account. No subscriptions in v1.0.0.
Minimum iOS 26.
```

**Contact**

| Field | Value |
|-------|-------|
| First name | `[Your first name]` |
| Last name | `[Your last name]` |
| Phone | `[Your phone with country code]` |
| Email | `[Your App Store contact email]` |

**Sign-in required?** No

---

## Version & build

| Field | Value |
|-------|-------|
| Version | 1.0.0 |
| Build | 1 |
| Copyright | `2026 [Your Legal Name or Company]` |
| Trade representative contact (if needed) | `[Same as review contact]` |

---

## Pricing

| Field | Value |
|-------|-------|
| Price | Free |
| Availability | All countries you distribute to (or start with primary markets) |
| App Store distribution | Public |

---

## App Privacy (nutrition label)

Match App Store Connect answers to the product. Suggested answers for v1:

**Data Not Collected** for tracking / advertising / analytics vendors — Qiyama does not track across apps or sell data.

If Apple asks about data linked to the user / used for product functionality, be accurate:

| Type | Collected? | Linked to identity? | Used for tracking? | Purpose |
|------|------------|---------------------|--------------------|---------|
| Location (coarse / for Fajr calc) | Yes — on device for prayer time | No account; stays on device | No | App Functionality |
| Photos / Camera | Camera only to scan QR; not saved to library by default | No | No | App Functionality |
| Product interaction / other | Wake outcomes stored locally | No | No | App Functionality |

If your build never leaves the device and you prefer the simpler path: declare only what ASC’s questionnaire forces for camera + approximate location used for Fajr. Do not claim “Data Not Collected” if you answer that location or camera-derived data is used for functionality — stay consistent with the privacy policy URL.

**Tracking:** No  
**Privacy nutrition must match** `PrivacyInfo.xcprivacy` (no tracking; UserDefaults for local prefs only).

---

## Screenshots

Use assets in `AppStoreAssets/iPhone-6.9/` (or regenerate). Required for the 6.9" iPhone display. Order suggestion:

1. Onboarding / mark  
2. Home — wake time  
3. Home — ready  
4. Wake — walk / scan  
5. Wake — simple  
6. Confirm  
7. Progress  
8. History  
9. Settings / profile  

Caption ideas (optional overlay; keep short):

- Wake before Fajr.  
- Walk to your mark.  
- Scan to prove you’re up.  
- Missed. Next is tomorrow.  
- Assistance drops as you hold.

---

## Export compliance

Already in the binary (`ITSAppUsesNonExemptEncryption = false`). In App Store Connect, answer that the app only uses exempt encryption (HTTPS / standard OS crypto) or does not use non-exempt encryption — consistent with the Info.plist key.

---

## Checklist before Submit for Review

- [ ] Privacy Policy URL live (`PRIVACY.md` on GitHub `main`)
- [ ] Support URL live (GitHub Issues)
- [ ] Marketing URL left blank (optional)
- [ ] Screenshots uploaded (6.9" minimum)  
- [ ] Description / subtitle / keywords pasted  
- [ ] Age rating questionnaire completed  
- [ ] App Privacy answers saved  
- [ ] Build 1.0.0 (1) selected  
- [ ] Review notes + contact filled  
- [ ] TestFlight smoke test on a real device (alarms + scan)

Upload binary:

```bash
./scripts/archive-appstore.sh
```

# TauntBuddy 🐹🎓

**Your judgemental study buddy.** A cross-platform (Web + Mobile) Flutter app that
keeps you in deep focus with an agentic, GitHub-fed taunt engine, a Pomodoro-based
Ekagra timer, the KAVACH distraction shield, an exam planner, mindfulness timers,
study circles and a gamified badge system — all wrapped in a Dark Neon /
Glassmorphism interface with an animated hamster mascot as the living brand mark.

> _"Kyuki kal karunga se degree nahi milti."_

---

## Table of contents

- [Feature suite](#feature-suite)
- [Design language](#design-language)
- [Architecture](#architecture)
- [Getting started](#getting-started)
- [Builds](#builds)
- [The taunt engine](#the-taunt-engine)
- [Notifications](#notifications)
- [KAVACH native shield](#kavach-native-shield)
- [Datasets](#datasets)
- [CI/CD](#cicd)
- [Branding assets](#branding-assets)
- [Repository layout](#repository-layout)
- [Privacy](#privacy)
- [License](#license)

---

## Feature suite

| Feature | What it does |
| --- | --- |
| 🏠 **Home** | Exact greeting headline, level/XP hero card, quick-access feature grid and the full feature list. |
| 📊 **Dashboard** | Daily inspiration quote, Today's Mood check-in, Today's Goals tracker (`0/0 done`), active streak counter, unlocked badges, and a monthly snapshot with **Consistency %**, **Completion rate** and **Average focus depth per day**. |
| ⚡ **Ekagra** | Pomodoro / deep-focus timer that records **Ekagra Depth** per day (quality-weighted focus minutes), configurable focus/short-break/round counts, session history. |
| 🎯 **Exam Planner** *(PRO)* | Syllabus tracking with units left per subject, days-to-exam countdown, `units/day to finish`, timeline templates and today's planner tasks. |
| 🛡️ **KAVACH** | Focus shield: integrity score, arming/disarming, profile-based strictness, native Android foreground shield + overlay chip, and a breach log. |
| 🏅 **Leaderboard & Badges** | Local rank merged into the global board plus a badge shelf driven by real in-app metrics. |
| 📚 **Courses** | Curated study tracks with category filters, per-lesson progress and one-tap "start an Ekagra block" hand-off. |
| 👥 **Mehfil & Study Circle** | Social study rooms; joining one starts a real local session so the room is honest about what it can promise. |
| 🧘 **Dhyan** | Mindfulness/meditation timer with mood-aware copy, technique list and monthly Dhyan minutes. |
| 🕒 **Timeline & Clock** | Live clock, the day as blocks (past/now/next), and tap-a-block-to-plan-a-task. |
| 🔍 **Search** | Global search across features, courses, circles, taunts and planner tasks. |
| 📈 **Analytics** | 7/14/30-day windows: consistency ring, completion rate, average depth per day, focus bar chart, mood curve and the session log. |
| 📣 **Taunt Vault** | The GitHub-synced taunt engine made visible: sync status, intensity control, search/filter by trigger, favourites, copy, and "send this taunt now". |
| 👤 **Profile & Settings** | Account details (device-local), editable profile + avatar, and settings for theme, notifications, study config, KAVACH, dataset sync and about. |

## Design language

- Canvas `#0C0B10` (alt `#121212`), glass surfaces `#14121B` at 6–14 % opacity.
- Electric violet accents `#9D4EDD` / `#8A2BE2` with soft neon glow `#B388FF`;
  magenta `#F72585`, cyan `#4CC9F0`, mint `#3DDC97`, amber `#FFB703` as
  supporting accents.
- **Bold white headers** (`w800`, negative letter-spacing) over **muted grey
  subtext**, heavily rounded cards (18–28 px radius) with 1 px subtle borders.
- Dark / Light / System theme selector, available from **both** Settings and the
  side menu.
- Navigation: glass drawer (12 destinations) + bottom nav bar
  (Home · Dashboard · Library · Analytics · Settings) with fade-through
  transitions, plus a floating taunt button and a running-session strip.
- The hamster mascot is drawn with a `CustomPainter` — no mascot image assets —
  and animates through idle float, blinking and pose transitions (judging,
  focus, celebrate, sleepy, shield, thinking).

Full palette, mascot poses and asset contract: [`docs/BRANDING.md`](docs/BRANDING.md).

## Architecture

```
lib/
├── app.dart                # TauntBuddyBoot.create() – composition root + routing
├── main.dart               # SystemChrome + runApp
├── core/
│   ├── router/             # route table + AppRouter.go()
│   ├── theme/              # AppTokens theme extension, AppTheme, ThemeController
│   ├── utils/              # date maths, validators, icon mapper
│   └── widgets/            # glass kit, mascot, ambient background, ui_kit, form fields
├── data/
│   ├── models/             # Taunt, UserProfile, AppSettings, FocusSession, tracking, Quote, catalog
│   ├── repositories/       # taunt / activity / catalog repositories (persistence + maths)
│   └── services/           # storage, GitHub source, notifications, reminders, KAVACH channel
├── state/                  # AppState, ActivityController, EkagraController, KavachController, ShellController
└── features/               # one folder per screen + shared sub-widgets
```

- **Provider** for state; controllers are plain `ChangeNotifier`s with a single
  `TauntBuddyBoot.create()` graph that wires storage → settings → controllers.
- **Repositories own the maths.** `AnalyticsSnapshot`, `depthScore`,
  `metricValue` and streak calculation live in one place so the dashboard, the
  analytics screen and the badge engine can never disagree.
- **Graceful degradation everywhere.** No network, no notification permission,
  no native platform implementation — the app still runs and says so.

## Getting started

```bash
git clone https://github.com/dastaanenajdik/Tauntbuddy.git
cd Tauntbuddy
flutter pub get
flutter run -d chrome      # web
flutter run -d android     # mobile
```

Requirements: Flutter **≥ 3.38.1** / Dart **≥ 3.10**. The repo ships `android/`
and `web/`; add the remaining targets any time with:

```bash
bash tools/add_platforms.sh            # ios, macos, linux, windows
bash tools/add_platforms.sh linux      # or pick specific ones
```

## Builds

```bash
flutter analyze                                  # static analysis (strict casts/inference)
flutter test --coverage                          # unit + widget tests
flutter build web --release                      # build/web
flutter build apk --release --no-shrink          # Android APK
flutter build appbundle --release --no-shrink    # Play Store AAB
```

Release signing reads `android/key.properties` (see the commented block in
`android/app/build.gradle`); without it, release builds fall back to the debug
key so CI and local builds never break.

## The taunt engine

1. **Bundled pack** — `assets/data/taunts.json` (31 Hinglish taunts across 7
   packs) always ships with the app, so notifications work offline on first run.
2. **GitHub sync** — at startup and on demand the app fetches the same file from
   `raw.githubusercontent.com/dastaanenajdik/Tauntbuddy/main/assets/data/taunts.json`
   (12 s timeout, never throws, schema-version checked) and caches it locally.
3. **Deterministic selection** — `TauntDataset.pick()` selects by trigger
   (morning / afternoon / evening / night / idle / goal missed / streak lost /
   session end / break over / exam soon / KAVACH breach / comeback / milestone),
   with a per-slot seed, a severity cap from the user's **taunt intensity**
   setting, and a recent-taunts exclusion list.
4. **Scheduling** — up to 6 daily slots (ids `9001–9006`) are (re)scheduled with
   the OS through `flutter_local_notifications`, so the hamster nags you even
   when the app is closed. Tests and manual taunts use id `4242`, round-complete
   notifications use `7000 + round`.

Notifications are requested **gracefully on startup** (skip-able, explained) and
the app always exposes the OS-level settings shortcut when permission is denied.
Sending a taunt from the Vault, or tapping a notification, surfaces the same
mascot line in-app.

## KAVACH native shield

`lib/data/services/kavach_service.dart` talks to
`com.tauntbuddy.app/tauntbuddy_native`:

| Method | Android behaviour |
| --- | --- |
| `isSupported` | `true` on Android, `false` on web/desktop |
| `hasOverlayPermission` / `requestOverlayPermission` | `Settings.canDrawOverlays` + the *Display over other apps* screen |
| `startShield` | Foreground `KavachForegroundService` with a persistent notification (plus the overlay chip when granted) |
| `stopShield` | Stops the service, clears the armed flag |
| `consumeBreaches` | Drains the breach counter recorded while the app was backgrounded |

`onStop()` records a breach whenever the app is left with the shield armed, and
the Dart controller merges that count on resume — the two sides can never
double-count. On any other platform the channel degrades silently to the pure
Dart lifecycle detection.

## Datasets

| File | Purpose |
| --- | --- |
| `assets/data/taunts.json` | Taunt packs, triggers, severity + category |
| `assets/data/quotes.json` | Daily inspiration quotes |
| `assets/data/seed_catalog.json` | Features, badges, levels, courses, circles, leaderboard, moods, Dhyan techniques, planner templates, KAVACH profiles, timeline blocks |

Validate by hand with the same script CI uses:

```bash
python3 .github/scripts/validate_taunts.py assets/data
```

## CI/CD

| Workflow | Trigger | What it does |
| --- | --- | --- |
| [`ci.yml`](.github/workflows/ci.yml) | push (main, `arena/**`), PRs | format report, `flutter analyze`, `flutter test --coverage`, then release **APK + AAB** and **web** builds uploaded as artefacts |
| [`taunts.yml`](.github/workflows/taunts.yml) | dataset changes, nightly 03:20 IST, manual | validates the bundled JSON, health-checks the **published** raw copy, opens an issue when the live dataset breaks, and mirrors validated data to a `dataset-snapshot` branch |
| [`release.yml`](.github/workflows/release.yml) | `v*` tags, manual | re-verifies, rebuilds Android + Web artefacts and publishes a GitHub Release |

## Branding assets

Everything (launcher icons, PWA icons, in-app brand marks) is generated from one
dependency-free Dart rasteriser:

```bash
dart run tools/generate_branding_assets.dart
```

The legacy single-file page at the repository root (`index.html`) is kept for the
original TauntBuddy link; the Flutter web app builds to `build/web`.

## Repository layout extras

```
.github/        workflows (CI, dataset, release) + dataset validator script
android/        hand-wired Gradle project, KAVACH service, adaptive icons
assets/         branding + JSON datasets
docs/           BRANDING.md
lib/            application code (see Architecture)
test/           dataset contract, taunt engine, date maths, validators, widgets
tools/          branding generator, add_platforms.sh
web/            index.html splash, manifest, generated icons
```

## Privacy

TauntBuddy is **local-first**. Accounts are device-local (no server, no
credentials leaving the phone), study data lives in `SharedPreferences` under
`tb.*`, and the only network call is the anonymous HTTPS fetch of the public
taunt/quote JSON from GitHub. Notifications, KAVACH overlay permission and
anything else sensitive are opt-in and explained before they are requested.

## License

MIT © 2026 TauntBuddy — see [LICENSE](LICENSE).

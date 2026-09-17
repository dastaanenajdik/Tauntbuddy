# TauntBuddy 🐹🎓

**Your judgemental study buddy.** A cross-platform (Web + Mobile) Flutter app that
keeps you in deep focus with an agentic taunt engine fed by the ifallertzia
server, a Pomodoro-based
Ekagra timer, the KAVACH distraction shield, an **Exam Hub** covering 26 Indian
competitive exams, an exam planner, mindfulness timers, study circles and a
gamified badge system — all wrapped in a **Solid Neon** interface with an animated
hamster mascot as the living brand mark.

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
| 🎯 **Exam Planner** *(PRO)* | Syllabus tracking with units left per subject, days-to-exam countdown, `units/day to finish`, timeline templates (including live exam blueprints) and today's planner tasks. |
| 🎓 **Exam Hub** | 26 Indian exams — UPSC CSE/ESE, BPSC, State PCS, SSC CGL/CHSL, RRB, IBPS/SBI/RBI, NDA/CDS, CA, CLAT, CAT, JEE, NEET, GATE, CUET, UGC NET, CTET — each with the official **exam pattern**, a paper-wise **syllabus**, the **annual cycle timeline** and eligibility. One tap turns any exam into planner subjects with a real exam date. |
| 🛡️ **KAVACH** | Focus shield: integrity score, arming/disarming, profile-based strictness, native Android foreground shield + overlay chip, and a breach log. |
| 🏅 **Leaderboard & Badges** | Local rank merged into the global board plus a badge shelf driven by real in-app metrics. |
| 📚 **Courses** | Curated study tracks with category filters, per-lesson progress and one-tap "start an Ekagra block" hand-off. |
| 👥 **Mehfil & Study Circle** | Social study rooms; joining one starts a real local session so the room is honest about what it can promise. |
| 🧘 **Dhyan** | Mindfulness/meditation timer with mood-aware copy, technique list and monthly Dhyan minutes. |
| 🕒 **Timeline & Clock** | Live clock, the day as blocks (past/now/next), and tap-a-block-to-plan-a-task. |
| 🔍 **Search** | Global search across features, exams, courses, circles, taunts and planner tasks. |
| 📈 **Analytics** | 7/14/30-day windows: consistency ring, completion rate, average depth per day, focus bar chart, mood curve and the session log. |
| 📣 **Taunt Vault** | The ifallertzia-server synced taunt engine made visible: sync status, intensity control, search/filter by trigger, favourites, copy, and "send this taunt now". |
| 👤 **Profile & Settings** | Account details (device-local), editable profile + avatar, and settings for theme, notifications, study config, KAVACH, dataset sync and about. |

## Design language

**Solid Neon**: bright violet accents on opaque panels. Nothing is washed out and
nothing is decorated with a rule — text sits on solid surfaces and the UI never
uses an underline or a strikethrough.

- Dark canvas `#131120` (alt `#1B1830`) with solid surfaces `#1B1830` /
  `#262242` — every panel is **100 % opaque**, borders `#3B3462`.
- Light canvas `#F5F4FA` (alt `#E9E5F6`) on white surfaces, borders `#D6CDEA`.
- Violet primary `#A855F7` / deep `#7C3AED` / glow `#C4A2FF` (dark) and
  `#6D28D9` / `#5B21B6` / `#8B5CF6` (light), with magenta `#FF4FA3`, cyan
  `#56CFF1`, mint `#3FE0B0`, amber `#FFC94D` as supporting accents.
- **Bold headers** (`w800`, negative letter-spacing) in `#FFFFFF` / `#14111F`
  over muted copy `#BDB8D4` / `#4B4660`; heavily rounded cards (18–28 px radius).
- Contrast is a tested contract, not a vibe: body text clears **17:1** and muted
  copy clears **8.9:1** on both themes (WCAG AAA needs 7:1). Enforced by
  `test/brand_smoke_test.dart`.
- Dark / Light / System theme selector, available from **both** Settings and the
  side menu.
- Navigation: drawer (13 destinations, Exam Hub included) + bottom nav bar
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
│   ├── models/             # Taunt, UserProfile, AppSettings, FocusSession, tracking, Quote, catalog, exam
│   ├── repositories/       # taunt / activity / catalog repositories (persistence + maths)
│   └── services/           # storage, ifallertzia server source, notifications, reminders, KAVACH channel
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

## Deploy to Vercel / Render

Both hosts build the **full Flutter web app** with one shared script —
[`tools/build_web_deploy.sh`](tools/build_web_deploy.sh) installs Flutter
(`stable`, overridable via the `FLUTTER_VERSION` env var, retries the SDK
clone on flaky provider networks), runs `flutter build web --release` (the
same command CI proves green on every push) and publishes `build/web`:

| Route | Content |
| --- | --- |
| `/` | Flutter web app (hash-routed SPA — no server rewrites needed) |
| `/classic.html` | legacy single-file TauntBuddy page |
| `/study-hub/` | Study Hub / Exam Hub **with the six photographic backgrounds** (`study-hub/assets/bg-*.jpg`) — these now ship inside the deploy output |
| `/build-info.txt` | commit + UTC build stamp, so the live revision is easy to verify |

**Vercel**: Import the repo (Vercel reads [`vercel.json`](vercel.json)
automatically — no manual settings), or hit **Redeploy** on the existing
project. The repo must be public (or connected with access) for the build
container to clone it.

**Render**: Dashboard → **New + → Blueprint** → pick this repo —
[`render.yaml`](render.yaml) creates the preconfigured **static site**
(build: `bash tools/build_web_deploy.sh`, publish dir: `build/web`). No
secrets or env vars are required.

`tools/vercel_build.sh` is kept as a back-compat shim for any Vercel project
that still points at it — it simply forwards to the shared script.

## The taunt engine

1. **Bundled pack** — `assets/data/taunts.json` (31 Hinglish taunts across 7
   packs) always ships with the app, so notifications work offline on first run.
2. **ifallertzia server sync** — at startup and on demand the app fetches the same
   dataset from the ifallertzia server endpoint
   (`raw.githubusercontent.com/dastaanenajdik/Tauntbuddy/main/assets/data/taunts.json`)
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
| `assets/data/seed_catalog.json` | Features, badges, levels, courses, circles, leaderboard, moods, Dhyan techniques, planner templates, KAVACH profiles, timeline blocks and the 26 **exam blueprints** (pattern, syllabus, cycle) |

Validate by hand with the same script CI uses:

```bash
python3 .github/scripts/validate_taunts.py assets/data
```

## CI/CD

| Workflow | Trigger | What it does |
| --- | --- | --- |
| [`ci.yml`](.github/workflows/ci.yml) | push (main, `arena/**`), PRs | dataset validation, format report, `flutter analyze`, `flutter test --coverage`, then release **APK + AAB** and **web** builds uploaded as artefacts |
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
study-hub/      the web Study Hub: Exam Hub · Courses · Planner · Pomodoro (see below)
test/           dataset contract, taunt engine, date maths, validators, widgets
tools/          branding generator, add_platforms.sh
web/            index.html splash, manifest, generated icons
```

### Study Hub (web companion)

`study-hub/` is a zero-dependency modular web app (plain ES modules — no build
step) that brings the Exam Hub, a detailed day-by-day exam planner and the
Pomodoro engine to the browser:

```
study-hub/
├── index.html                  shell only — no inline app code
├── css/                        tokens · base · layout · components · views
├── data/exams.js               8 exam tracks, full subject/unit/chapter names
├── assets/                     section background photography (bundled)
├── js/
│   ├── app.js                  bootstrap + running-session strip
│   ├── router.js               hash router with per-view cleanup hooks
│   ├── store.js                reactive localStorage store (v3, migrate-safe)
│   ├── ui.js                   DOM helpers, esc(), toasts
│   └── features/
│       ├── home/ · courses/    landing, course grid + Exam Hub detail
│       ├── planner/            plan-generator (pure) + lazy week accordions
│       └── pomodoro/           singleton timer engine + reusable widget
└── tools/                      plan unit tests, jsdom DOM smoke test,
                                contrast checker (WCAG contract)
```

Run it with any static server, e.g. `python3 -m http.server -d study-hub 8021`.
Checks: `node study-hub/tools/plan.test.mjs`, `node study-hub/tools/dom.smoke.mjs`
(needs a one-off `npm install --no-save jsdom` inside `study-hub/`) and
`python3 study-hub/tools/contrast_check.py`.

## Privacy

TauntBuddy is **local-first**. Accounts are device-local (no server, no
credentials leaving the phone), study data lives in `SharedPreferences` under
`tb.*`, and the only network call is the anonymous HTTPS fetch of the public
taunt/quote JSON from the ifallertzia server. Notifications, KAVACH overlay permission and
anything else sensitive are opt-in and explained before they are requested.

## License

MIT © 2026 TauntBuddy — see [LICENSE](LICENSE).

---

made with ❤️ by **Siddharth ifallertzia** — _kyuki kal karunga se degree nahi milti._

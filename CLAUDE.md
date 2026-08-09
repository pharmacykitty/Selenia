# Ecliptica (working title)

> A real-ephemeris astrology app for iOS — natal charts, transits, synastry, predictive work, and a 3D celestial sphere — built to be genuinely beautiful. Split out of the Astrolabe planetarium app on 2026-07-15 so each app has one focused identity.

**Status:** pre-release. The name is a working title (`com.astrolabe.ecliptica`); final App Store name TBD.

## The vision

Everything is computed, not looked up: charts run on real ephemeris math (`CelestialCore`) with the symbolic layer (`Astrology`) on top. Accuracy is a feature — positions should match astro.com. The 3D celestial sphere renders the *actual* sky (real HYG stars, real constellation figures) with the chart drawn onto it: the astrophysics × astrology bridge.

## Architecture

```
project.yml            # XcodeGen spec — Ecliptica.xcodeproj is generated, not committed
App/
  EclipticaApp.swift   # @main; SwiftData container (SavedChart); snapshot-harness launch args
  Charts/              # chart UI: detail/editor/list, transits, predictive, synastry,
                       #   CelestialSphereView (3D sphere), SphereExport, ChartShareCard,
                       #   TransitNotifications, BirthdayReminders, SavedChart (@Model)
  Screens/             # AstrologyHomeView (root hub), AstrologyView (Sky Now), AstrologyModel,
                       #   ChartWheel, AboutView (Sources — the canonical attribution list)
  Sky/                 # StarCatalogStore + Constellations (loaders for the sphere's star field)
  DesignSystem/        # Theme (incl. Theme.astro tint), LuminousGlyph
  Resources/           # stars.bin (HYG binary catalog), constellation_lines.json
```

**Sibling-repo requirement:** packages are referenced by relative path — check out as
```
~/Developer/AstroPackages/   # CelestialCore + Astrology packages (own repo)
~/Developer/Ecliptica/       # this repo
```
(`~/Developer/Astrolabe` is the sister astronomy app, sharing `CelestialCore` and the duplicated `Theme`/`StarCatalogStore`/`Constellations` files — if you fix a bug in one of those duplicates, consider porting it to the other repo.)

- `CelestialCore` — pure astronomy math (time, coordinates, ephemeris, catalogs). `Astrology` — zodiac, houses, aspects, charts, transits, interpretation; depends only on CelestialCore. Both unit-tested; run `swift test` in each package after touching them.
- Specs: `docs/astrology-spec.md` (math + decisions), `docs/astrology-features.md` (feature set), `docs/celestial-sphere.md` (the 3D sphere design).

## Conventions

- Swift 6, strict concurrency.
- **No emojis anywhere in the UI.** Use text-presentation Unicode glyphs; zodiac signs (U+2648…U+2653) and ♀/♂ need the U+FE0E variation selector — never hardcode glyph literals, reuse `ZodiacSign.glyph` / `AstroBody.glyph`.
- **No Swiss Ephemeris** (AGPL/paid) — own math on CelestialCore + SwiftAA (MIT).
- **Keep sources current:** any new dataset/library/algorithm gets an entry in `SourceCatalog` (`App/Screens/AboutView.swift` — the user-facing Sources screen) before shipping.

## Build & verify

```sh
xcodegen generate
xcodebuild -project Ecliptica.xcodeproj -scheme Ecliptica \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  ENABLE_DEBUG_DYLIB=NO ENABLE_PREVIEWS=NO build
xcrun simctl install booted <BUILT_PRODUCTS_DIR>/Ecliptica.app
xcrun simctl launch booted com.astrolabe.ecliptica
xcrun simctl io booted screenshot shot.png
```
(`ENABLE_DEBUG_DYLIB=NO` matters — the debug-dylib thunk never registers with simctl.)

Debug launch args (screenshot harnesses): `-snapshotSphere [tour|time]`, `-exportTest`, `-snapshotAstro <screen>`.

## Backlog (carried from the split)

- ★ Transit-to-sky: tap a transit, see where that planet is in the real sky (deep-link to the Astrolabe app?).
- ★ Void-of-course Moon indicator.
- ★ Precession-gap "signs vs constellations" explainer.
- Settings/preferences (no `AppStorage` yet: default house system/zodiac, "Today" chart persist per-launch only).
- Accessibility (Dynamic Type, VoiceOver for the wheel/sphere), localization (EN+ES), widgets (daily reading / transit alerts), onboarding, app icon + launch screen (no asset catalog yet — ship blocker).
- Final name + App Store availability check.

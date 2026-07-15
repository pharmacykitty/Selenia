# Ecliptica

A real-ephemeris astrology app for iOS: natal charts, transits, progressions & returns, synastry, daily readings, and a 3D celestial sphere that draws your chart onto the *actual* sky (real HYG stars + constellation figures).

Split out of the [Astrolabe](../Astrolabe) planetarium app — same math engine, one focused product.

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/astro-home.png" width="240"><br><sub><b>The hub</b> — today, live sky, charts</sub></td>
    <td align="center"><img src="docs/screenshots/natal-chart.png" width="240"><br><sub><b>Natal chart</b> — wheel, patterns, readings</sub></td>
    <td align="center"><img src="docs/screenshots/sphere.png" width="240"><br><sub><b>3D celestial sphere</b> — your sky as a globe</sub></td>
  </tr>
</table>

## Setup

Requires sibling checkouts (packages are referenced by relative path):

```
~/Developer/AstroPackages/   # CelestialCore + Astrology Swift packages
~/Developer/Ecliptica/       # this repo
```

```sh
brew install xcodegen
xcodegen generate
open Ecliptica.xcodeproj
```

## Tests

The math lives in the packages: `cd ../AstroPackages/CelestialCore && swift test`, same for `Astrology`.

## Data & credits

HYG Database (public domain), d3-celestial constellation lines (BSD-3), SwiftAA (MIT), JPL SBDB. The in-app **About → Sources** screen (`App/Screens/AboutView.swift`) is the canonical attribution list.

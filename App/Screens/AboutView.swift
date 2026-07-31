import SwiftUI

/// The About / Sources screen. Credits every dataset, library, and reference the
/// app relies on, with licences and links — both to honour attribution terms
/// (several are required before shipping) and because the data provenance is part
/// of the product. Keep this in sync as new sources are added (see `CLAUDE.md`).
struct AboutView: View {
    var body: some View {
        ZStack {
            Theme.spaceGradient.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    header
                    ForEach(SourceCatalog.groups) { group in
                        sourceGroup(group)
                    }
                    footer
                }
                .padding()
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Sources")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: 12) {
            LuminousGlyph(symbol: "books.vertical.fill", tint: .gray, size: 96, glyphSize: 40)
            Text("Sources & Credits")
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .foregroundStyle(.white).multilineTextAlignment(.center)
            Text("Every position in Ecliptica is computed from real ephemeris math and open astronomical data. The people and projects behind them:")
                .font(.subheadline).foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }

    private func sourceGroup(_ group: SourceGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(group.title.uppercased())
                .font(.caption.weight(.semibold)).tracking(1.6)
                .foregroundStyle(.white.opacity(0.45))
                .padding(.leading, 4)
            VStack(spacing: 0) {
                ForEach(group.entries) { entry in
                    sourceRow(entry, isLast: entry.id == group.entries.last?.id)
                }
            }
            .luminousSurface(group.tint)
        }
    }

    private func sourceRow(_ entry: SourceEntry, isLast: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(entry.name).font(.headline).foregroundStyle(.white)
                Spacer()
                if let license = entry.license {
                    Text(license).font(.caption2.weight(.medium))
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(.white.opacity(0.10), in: Capsule())
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            Text(entry.detail).font(.subheadline).foregroundStyle(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
            if let url = entry.url, let link = URL(string: url) {
                Link(destination: link) {
                    Text(url.replacingOccurrences(of: "https://", with: ""))
                        .font(.caption).foregroundStyle(Theme.accent)
                        .lineLimit(1).truncationMode(.middle)
                }
            }
        }
        .padding(14)
        .overlay(alignment: .bottom) {
            if !isLast { Divider().background(.white.opacity(0.08)) }
        }
    }

    private var footer: some View {
        VStack(spacing: 6) {
            Text("Ecliptica")
                .font(.system(.headline, design: .serif)).foregroundStyle(.white.opacity(0.8))
            Text("Built with respect for the open astronomy community.")
                .font(.caption).foregroundStyle(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}

// MARK: - Source data

struct SourceEntry: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    var license: String? = nil
    var url: String? = nil
}

struct SourceGroup: Identifiable {
    let id = UUID()
    let title: String
    let tint: Color
    let entries: [SourceEntry]
}

/// The single source of truth for the app's attributions. Add to this whenever a
/// new dataset, library, or algorithm is introduced (see `CLAUDE.md` convention).
enum SourceCatalog {
    static let groups: [SourceGroup] = [
        SourceGroup(title: "Astrology", tint: .orange, entries: [
            SourceEntry(name: "Rolled our own",
                        detail: "All astrology math (zodiac, ayanamsa, Ascendant/MC, house systems, aspects, charts) is computed on CelestialCore — no Swiss Ephemeris (AGPL/commercial). Validated against astro.com reference charts.",
                        license: "In-house"),
            SourceEntry(name: "House systems & aspects",
                        detail: "Placidus / Whole Sign / Equal / Porphyry cusps and major/minor aspect definitions from published astrological references.",
                        license: "Reference"),
            SourceEntry(name: "Lahiri ayanamsa",
                        detail: "Sidereal-zodiac offset for the sidereal calculation mode.",
                        license: "Reference"),
            SourceEntry(name: "JPL Small-Body Database",
                        detail: "Osculating orbital elements for Chiron and the asteroids Ceres, Pallas, Juno, and Vesta, propagated by two-body Kepler motion for the optional points layer. Validated against JPL Horizons.",
                        license: "Public domain",
                        url: "https://ssd.jpl.nasa.gov/tools/sbdb_lookup.html"),
        ]),
        SourceGroup(title: "Ephemeris & Astronomy Math", tint: .purple, entries: [
            SourceEntry(name: "Astronomical Algorithms (Meeus)",
                        detail: "Jean Meeus' standard reference — the basis for our Julian date, sidereal time, coordinate transforms, and Sun (Ch. 25), Moon (Ch. 47), and Pluto (Ch. 37) positions.",
                        license: "Reference"),
            SourceEntry(name: "SwiftAA",
                        detail: "Swift port of Meeus' algorithms by onekiloparsec; used for Mercury–Neptune apparent geocentric ecliptic longitudes.",
                        license: "MIT",
                        url: "https://github.com/onekiloparsec/SwiftAA"),
            SourceEntry(name: "VSOP87 planetary theory",
                        detail: "Bretagnon & Francou's analytical planetary theory, underpinning the planet positions used in charts.",
                        license: "Reference"),
        ]),
        SourceGroup(title: "Star Catalogs", tint: .yellow, entries: [
            SourceEntry(name: "HYG Database",
                        detail: "~119k stars combining the Hipparcos, Yale Bright Star, and Gliese catalogs — the real star field behind the 3D celestial sphere. Compiled by David Nash (astronexus).",
                        license: "Public domain",
                        url: "https://github.com/astronexus/HYG-Database"),
            SourceEntry(name: "Hipparcos & Tycho Catalogues",
                        detail: "ESA's astrometric survey — the precise star positions underlying the HYG data. (This app uses sky directions only; the sister Astrolabe app uses the parallax distances too.)",
                        license: "ESA / public"),
            SourceEntry(name: "Constellation lines",
                        detail: "Stick-figure constellation geometry from the d3-celestial project by Olaf Frohn, drawn faintly on the celestial sphere.",
                        license: "BSD-3-Clause",
                        url: "https://github.com/ofrohn/d3-celestial"),
        ]),
    ]
}

#Preview {
    NavigationStack { AboutView() }
        .preferredColorScheme(.dark)
}

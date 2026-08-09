import SwiftUI
import simd
import CelestialCore
import Astrology

// SwiftUI also declares `Angle`; here we always mean the astronomy one.
private typealias Angle = CelestialCore.Angle

/// The invitation to the 3D sphere (2026-08-08 feedback: "make the thing with
/// the globe more prominent"): a live miniature of the celestial globe rising
/// like a dome out of a wide card — horizon, ecliptic, planets and the
/// brightest stars, slowly turning. Purely visual; wrap it in a NavigationLink
/// to the full `CelestialSphereView`.
struct SphereDomeCard: View {
    let chart: NatalChart
    var store: StarCatalogStore? = nil

    @State private var model: DomeModel?
    @State private var onScreen = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    // Calmer than the full sphere's one turn per minute — this is an accent,
    // not the hero.
    private static let spinRate = 2 * Double.pi / 90

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let model {
                TimelineView(.animation(minimumInterval: 1.0 / 24.0,
                                        paused: !onScreen || reduceMotion)) { tl in
                    Canvas { ctx, size in
                        let yaw = reduceMotion ? 0.7
                            : tl.date.timeIntervalSinceReferenceDate * Self.spinRate
                        model.draw(in: ctx, size: size, yaw: yaw)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Your sky as a globe")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.astro.opacity(0.7))
                }
                Text("Live — spin it, tap the planets")
                    .font(.caption).foregroundStyle(.white.opacity(0.55))
            }
            .padding(.horizontal, 14).padding(.top, 12)
        }
        .frame(height: 132)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [Color(red: 0.05, green: 0.07, blue: 0.16),
                                    Color(red: 0.02, green: 0.03, blue: 0.07)],
                           startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: Theme.panelRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.panelRadius)
            .strokeBorder(Theme.astro.opacity(0.35), lineWidth: 1))
        // Stop the timeline when scrolled away; the card is a glance, not a tax.
        .onScrollVisibilityChange(threshold: 0.15) { onScreen = $0 }
        // Rebuild when the chart moves *or* the star catalog finishes loading
        // (the card usually appears before the async load completes).
        .task(id: "\(chart.julianDay.value)|\(store?.catalog?.stars.count ?? 0)") {
            model = DomeModel(chart: chart, stars: SphereStars.bright(from: store))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your sky as a globe. Opens the rotating 3D sphere.")
    }
}

/// Pared-back sphere geometry for the dome card: no Milky Way, houses, zodiac
/// glyphs or labels — just enough sky to be unmistakably the globe. Built in
/// the **ecliptic frame** (z = ecliptic north pole) and viewed from a high
/// pitch, so the planet-studded ecliptic band always arcs across the visible
/// crest of the dome no matter the chart — the card crops the lower half of
/// the sphere away. Planets sit flat on the ecliptic (their true latitude is
/// invisible at this size).
private struct DomeModel {
    let equator: [SIMD3<Double>]
    let ecliptic: [SIMD3<Double>]
    let starDots: [(v: SIMD3<Double>, r: Double)]
    let planets: [(v: SIMD3<Double>, body: AstroBody)]
    let aspects: [(a: SIMD3<Double>, b: SIMD3<Double>, kind: AspectKind)]

    init(chart: NatalChart, stars: [Star]) {
        let ob = chart.angles.obliquity.radians
        let cosE = cos(ob), sinE = sin(ob)
        func eclVec(lonDegrees lon: Double) -> SIMD3<Double> {
            let l = lon * .pi / 180
            return SIMD3(cos(l), sin(l), 0)
        }
        // Equatorial → ecliptic frame (rotation about the shared x-axis).
        func eqToEcl(_ eq: EquatorialCoordinates) -> SIMD3<Double> {
            let ra = eq.rightAscension.radians, dec = eq.declination.radians
            let v = SIMD3(cos(dec) * cos(ra), cos(dec) * sin(ra), sin(dec))
            return SIMD3(v.x, cosE * v.y + sinE * v.z, -sinE * v.y + cosE * v.z)
        }
        ecliptic = stride(from: 0.0, through: 360.0, by: 6.0).map { eclVec(lonDegrees: $0) }
        equator = stride(from: 0.0, through: 360.0, by: 6.0).map {
            eqToEcl(EquatorialCoordinates(rightAscension: .degrees($0), declination: .zero))
        }
        starDots = stars.sorted { $0.apparentMagnitude < $1.apparentMagnitude }.prefix(420)
            .map { (eqToEcl($0.equatorial), max(0.5, 1.9 - 0.24 * $0.apparentMagnitude)) }
        planets = chart.positions.map { (eclVec(lonDegrees: $0.longitude.degrees), $0.body) }
        let posByBody = Dictionary(uniqueKeysWithValues: chart.positions.map { ($0.body, $0.longitude) })
        // Only the tightest few chords — at card size a full aspect web is noise.
        aspects = chart.aspects.filter { $0.kind.isMajor }
            .sorted { $0.orb < $1.orb }.prefix(6)
            .compactMap { asp in
                guard let la = posByBody[asp.bodyA], let lb = posByBody[asp.bodyB] else { return nil }
                return (eclVec(lonDegrees: la.degrees), eclVec(lonDegrees: lb.degrees), asp.kind)
            }
    }

    func draw(in ctx: GraphicsContext, size: CGSize, yaw: Double) {
        // The sphere's centre sits just below the card's bottom edge, so the
        // upper hemisphere rises out of it like a planetarium dome. The high
        // pitch looks down from above the ecliptic pole, lifting the ring's
        // near arc into the visible crest.
        let radius = Double(size.height) * 0.82
        let center = CGPoint(x: size.width / 2, y: size.height + radius * 0.24)
        let pitch = 1.0
        func p(_ v: SIMD3<Double>) -> (CGPoint, Double) {
            let cyaw = cos(yaw), syaw = sin(yaw)
            let x1 = v.x * cyaw - v.y * syaw
            let y1 = v.x * syaw + v.y * cyaw
            let cp = cos(pitch), sp = sin(pitch)
            let y2 = y1 * cp - v.z * sp     // depth toward viewer
            let z2 = y1 * sp + v.z * cp     // screen vertical
            return (CGPoint(x: center.x + radius * x1, y: center.y - radius * z2), y2)
        }

        // Dome volume + rim.
        let limb = CGRect(x: center.x - radius, y: center.y - radius,
                          width: 2 * radius, height: 2 * radius)
        ctx.fill(Path(ellipseIn: limb),
                 with: .radialGradient(
                    Gradient(colors: [Color(red: 0.05, green: 0.08, blue: 0.18).opacity(0.9),
                                      Color(red: 0.01, green: 0.02, blue: 0.05).opacity(0.4)]),
                    center: center, startRadius: 0, endRadius: radius))
        ctx.stroke(Path(ellipseIn: limb),
                   with: .color(Color(red: 0.45, green: 0.58, blue: 0.95).opacity(0.4)), lineWidth: 1)

        // Split a ring into near/far arcs, matching the full sphere's language.
        func ring(_ pts: [SIMD3<Double>], color: Color, front: Double, back: Double, width: Double) {
            var f = Path(), b = Path()
            var inF = false, inB = false
            for v in pts {
                let (pt, depth) = p(v)
                if depth >= 0 {
                    if inF { f.addLine(to: pt) } else { f.move(to: pt); inF = true }
                    inB = false
                } else {
                    if inB { b.addLine(to: pt) } else { b.move(to: pt); inB = true }
                    inF = false
                }
            }
            ctx.stroke(b, with: .color(color.opacity(back)), lineWidth: width)
            ctx.stroke(f, with: .color(color.opacity(front)), lineWidth: width)
        }

        // Stars (near side, with a little tolerance past the limb so the
        // dome's crest doesn't thin out — the card reads solid at this size).
        var starPath = Path()
        for s in starDots {
            let (pt, depth) = p(s.v)
            guard depth >= -0.15 else { continue }
            starPath.addEllipse(in: CGRect(x: pt.x - s.r, y: pt.y - s.r,
                                           width: 2 * s.r, height: 2 * s.r))
        }
        ctx.fill(starPath, with: .color(Color(red: 0.92, green: 0.95, blue: 1.0).opacity(0.85)))

        ring(equator, color: Color(red: 0.45, green: 0.6, blue: 1.0), front: 0.3, back: 0.1, width: 0.6)
        // The ecliptic keeps its soft glow — it's the signature band.
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: 3))
            var f = Path()
            var inF = false
            for v in ecliptic {
                let (pt, depth) = p(v)
                if depth >= 0 {
                    if inF { f.addLine(to: pt) } else { f.move(to: pt); inF = true }
                } else { inF = false }
            }
            layer.stroke(f, with: .color(Color(red: 0.5, green: 1.0, blue: 0.6).opacity(0.5)),
                         lineWidth: 3)
        }
        ring(ecliptic, color: Color(red: 0.5, green: 1.0, blue: 0.6), front: 0.8, back: 0.2, width: 1.2)

        // Aspect chords, quiet.
        for arc in aspects {
            let (pa, da) = p(arc.a); let (pb, db) = p(arc.b)
            guard (da + db) / 2 >= -0.1 else { continue }
            ctx.stroke(Path { $0.move(to: pa); $0.addLine(to: pb) },
                       with: .color(SphereGeometry.aspectColor(arc.kind).opacity(0.32)),
                       lineWidth: 0.7)
        }

        // Planets: shared glow layer, then cores. Sun and Moon read larger.
        func coreRadius(_ body: AstroBody) -> Double {
            switch body { case .sun: 3.2; case .moon: 2.6; default: 1.9 }
        }
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: 3))
            for pl in planets {
                let (pt, depth) = p(pl.v)
                guard depth >= -0.05 else { continue }
                let r = coreRadius(pl.body) + 3
                layer.fill(Path(ellipseIn: CGRect(x: pt.x - r, y: pt.y - r, width: 2 * r, height: 2 * r)),
                           with: .color(SphereGeometry.planetColor(pl.body).opacity(0.5)))
            }
        }
        for pl in planets {
            let (pt, depth) = p(pl.v)
            guard depth >= -0.05 else { continue }
            let r = coreRadius(pl.body)
            ctx.fill(Path(ellipseIn: CGRect(x: pt.x - r, y: pt.y - r, width: 2 * r, height: 2 * r)),
                     with: .color(SphereGeometry.planetColor(pl.body)))
        }
    }
}

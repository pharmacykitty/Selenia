import SwiftUI
import SwiftData
import CelestialCore
import Astrology

/// The astrology hub: a personalised "today" (from a saved chart), a live preview
/// of the current sky, then the full live chart or saved birth charts.
struct AstrologyHomeView: View {
    var store: StarCatalogStore? = nil
    private let tint = Theme.astro

    @Query(sort: \SavedChart.createdAt, order: .reverse) private var charts: [SavedChart]
    @State private var model = AstrologyModel()
    @State private var selectedChartID: PersistentIdentifier?
    @State private var daily: DailyReading?
    @State private var mercuryRetro: RetrogradePeriod?
    @State private var editing = false

    private var selectedChart: SavedChart? {
        if let id = selectedChartID, let c = charts.first(where: { $0.persistentModelID == id }) { return c }
        return charts.first
    }

    var body: some View {
        ZStack {
            Theme.spaceGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    header
                    todaySection
                    livePreview
                    NavigationLink { SkyNowView(store: store) } label: {
                        HubCard(symbol: "sparkles", title: "Sky Now",
                                subtitle: "The live chart for your location", tint: tint)
                    }
                    NavigationLink { ChartListView(store: store) } label: {
                        HubCard(symbol: "person.crop.circle", title: "Saved Charts",
                                subtitle: "Birth charts you've saved", tint: tint)
                    }
                    NavigationLink { RelationshipsView(store: store) } label: {
                        HubCard(symbol: "heart.circle", title: "Relationships",
                                subtitle: "Compare two charts — synastry & composite", tint: tint)
                    }
                    NavigationLink { AboutView() } label: {
                        HubCard(symbol: "books.vertical", title: "About & Sources",
                                subtitle: "Data, credits & licenses", tint: .gray)
                    }
                }
                .padding(20)
            }
        }
        // The serif hero below owns the name (the sister apps' shared voice);
        // a nav-bar "Ecliptica" directly above it would print it twice.
        .navigationBarTitleDisplayMode(.inline)
        .buttonStyle(.plain)
        .task { await model.start() }
        .task(id: selectedChart?.persistentModelID) { await loadDaily() }
        .sheet(isPresented: $editing) { ChartEditorView() }
    }

    /// The serif hero — the same large-title voice Astrolabe's screens open with.
    private var header: some View {
        VStack(spacing: 4) {
            Text("Ecliptica")
                .font(.system(.largeTitle, design: .serif).weight(.bold))
                .foregroundStyle(.white)
            Text("The sky, read for you")
                .font(.subheadline).foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
    }

    // MARK: Today (F8)

    @ViewBuilder private var todaySection: some View {
        if charts.isEmpty {
            savePrompt
        } else if let chart = selectedChart {
            VStack(alignment: .leading, spacing: 8) {
                if charts.count > 1 { chartPicker(chart) }
                NavigationLink { SavedChartView(chart: chart, store: store) } label: {
                    todayHero(chart)
                }
            }
        }
    }

    private func chartPicker(_ chart: SavedChart) -> some View {
        Menu {
            ForEach(charts) { c in
                Button {
                    selectedChartID = c.persistentModelID
                } label: {
                    Label(c.name.isEmpty ? "Untitled" : c.name,
                          systemImage: c.persistentModelID == chart.persistentModelID ? "checkmark" : "")
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text("Daily reading for \(chart.name.isEmpty ? "Untitled" : chart.name)")
                    .font(.caption.weight(.medium)).foregroundStyle(.white.opacity(0.6))
                Image(systemName: "chevron.down").font(.caption2).foregroundStyle(tint)
            }
            .padding(.leading, 4)
        }
    }

    private func todayHero(_ chart: SavedChart) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TODAY · \(Date().formatted(.dateTime.month(.abbreviated).day()))")
                .font(.caption2.weight(.bold)).tracking(1).foregroundStyle(tint)
            if let daily {
                Text(daily.headline)
                    .font(.title3.weight(.semibold)).foregroundStyle(.white)
                Text(daily.body)
                    .font(.subheadline).foregroundStyle(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Reading today's sky…")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let r = mercuryRetro {
                HStack(spacing: 7) {
                    Text("☿℞").foregroundStyle(.orange)
                    Text(r.start <= Date()
                         ? "Mercury retrograde until \(r.end.formatted(date: .abbreviated, time: .omitted))"
                         : "Mercury retrograde from \(r.start.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption).foregroundStyle(.white.opacity(0.65))
                }
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Theme.panelRadius)
                .fill(.linearGradient(colors: [Color(red: 0.11, green: 0.07, blue: 0.19), Color(red: 0.05, green: 0.04, blue: 0.10)],
                                      startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(RoundedRectangle(cornerRadius: Theme.panelRadius).strokeBorder(tint.opacity(0.35), lineWidth: 1))
    }

    /// Pre-chart, the empty state is one quiet row — the live wheel below leads
    /// the page instead of a large glowing placeholder pinned above the fold.
    private var savePrompt: some View {
        HStack(spacing: 12) {
            LuminousGlyph(symbol: "sparkles", tint: tint, size: 40, glyphSize: 17)
            Text("Save a birth chart for your daily reading.")
                .font(.subheadline).foregroundStyle(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button { editing = true } label: {
                Label("New Chart", systemImage: "plus").font(.subheadline.weight(.medium))
            }
            .buttonStyle(.borderedProminent).tint(tint)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(Theme.nightInk.opacity(0.55), in: .rect(cornerRadius: Theme.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .strokeBorder(.white.opacity(0.12), lineWidth: 0.5)
        }
    }

    // MARK: Live preview (existing)

    private var livePreview: some View {
        VStack(spacing: 14) {
            ChartWheel(chart: model.chart)
                .frame(height: 210)
            HStack(spacing: 8) {
                bigThreeCell("Sun", model.position(.sun)?.position)
                bigThreeCell("Moon", model.position(.moon)?.position)
                bigThreeCell("Rising", ZodiacPosition(longitude: model.chart.angles.ascendant))
            }
            Text(model.locationLabel)
                .font(.caption).foregroundStyle(.white.opacity(0.45))
        }
        .padding(16)
        .luminousSurface(tint, cornerRadius: Theme.panelRadius, glow: 12)
    }

    private func bigThreeCell(_ label: String, _ pos: ZodiacPosition?) -> some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(.caption.weight(.semibold)).tracking(1.2)
                .foregroundStyle(.white.opacity(0.5))
            // The glyph takes its sign's element colour (the wheel's own palette)
            // instead of flattening all three to gold.
            Text(pos?.sign.glyph ?? "–")
                .font(.title2)
                .foregroundStyle(pos.map { Theme.element($0.sign.element) } ?? tint)
            Text(pos?.sign.name ?? "—")
                .font(.caption).foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Theme.nightInk.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.1), lineWidth: 0.5)
        }
    }

    // MARK: Loading

    private func loadDaily() async {
        guard let chart = selectedChart else { daily = nil; return }
        let natal = chart.makeChart()
        daily = await Task.detached(priority: .userInitiated) { Daily.reading(for: natal) }.value
        mercuryRetro = await Task.detached(priority: .utility) {
            Forecast.retrogrades(of: .mercury, days: 150, from: Date()).first { $0.end > Date() }
        }.value
    }
}

/// A large luminous destination card, matching the main menu's language.
struct HubCard: View {
    let symbol: String
    let title: String
    let subtitle: String
    let tint: Color

    var body: some View {
        HStack(spacing: 16) {
            LuminousGlyph(symbol: symbol, tint: tint, size: 52, glyphSize: 21)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline).foregroundStyle(.white)
                Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(tint.opacity(0.6))
        }
        .padding(16)
        // Hairline rim only — when every card glows, nothing does.
        .luminousSurface(tint, cornerRadius: Theme.panelRadius, glow: 0)
    }
}

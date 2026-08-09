import SwiftUI
import Astrology

/// A saved birth chart, recomputed from its stored inputs. Reuses the shared
/// `ChartDetailView`, with a link to the 3D sphere.
///
/// The chart is computed **once** in `.task` and cached, rather than rebuilt on
/// every render — building a chart is ~36 ephemeris evaluations, so doing it in
/// `body` made the page lag on every scroll/state change.
struct SavedChartView: View {
    let chart: SavedChart
    var store: StarCatalogStore? = nil

    @State private var natal: NatalChart?
    @State private var reminderDenied = false

    private var name: String { chart.name.isEmpty ? "Chart" : chart.name }

    var body: some View {
        Group {
            if let natal {
                ChartDetailView(
                    chart: natal,
                    title: name,
                    subtitle: chart.subtitle,
                    natalForTransits: natal,
                    toolbarTrailing: AnyView(HStack(spacing: 2) {
                        birthdayButton
                        sphereLink(natal)
                    }),
                    sphereInvite: AnyView(
                        NavigationLink {
                            sphereDestination(natal)
                        } label: {
                            SphereDomeCard(chart: natal, store: store)
                        }
                        .buttonStyle(.plain)
                    )
                )
            } else {
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.spaceGradient.ignoresSafeArea())
                    .navigationTitle(name)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .task(id: chart.persistentModelID) { natal = chart.makeChart() }
    }

    /// Toggle the annual birthday notification for this chart's person. The
    /// cake fills when armed; denied notification permission gets one gentle
    /// pointer to Settings instead of a silently dead button.
    private var birthdayButton: some View {
        let on = chart.birthdayReminderID != nil
        return Button {
            Task { @MainActor in
                if on {
                    BirthdayReminders.disable(for: chart)
                } else if await !BirthdayReminders.enable(for: chart) {
                    reminderDenied = true
                }
            }
        } label: {
            Image(systemName: on ? "birthday.cake.fill" : "birthday.cake")
                .accessibilityLabel(on ? "Birthday reminder on" : "Remind me of their birthday")
        }
        .tint(Theme.astro)
        .alert("Notifications are off", isPresented: $reminderDenied) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Allow notifications for Ecliptica in Settings to get birthday reminders.")
        }
    }

    private func sphereLink(_ natal: NatalChart) -> some View {
        NavigationLink {
            sphereDestination(natal)
        } label: {
            Image(systemName: "globe").accessibilityLabel("View in 3D sphere")
        }
        .tint(Theme.astro)
    }

    private func sphereDestination(_ natal: NatalChart) -> some View {
        CelestialSphereView(chart: natal, title: name,
                            subtitle: chart.subtitle, stars: SphereStars.bright(from: store),
                            constellations: store?.constellations ?? [])
    }
}

import SwiftUI
import SwiftData
import CelestialCore

@main
struct EclipticaApp: App {
    /// The HYG star catalog + constellation figures backing the 3D celestial
    /// sphere. Loaded eagerly so the sphere's star field is warm on first open.
    @State private var store = StarCatalogStore()

    var body: some Scene {
        WindowGroup {
            // Debug-only snapshot routes so the 3D sphere and chart screens can be
            // captured directly (the UI can't be scripted in the simulator).
            if ProcessInfo.processInfo.arguments.contains("-exportTest") {
                Color.black.ignoresSafeArea()
                    .task { await SphereSnapshotHarness.runExportTest() }
            } else if let i = ProcessInfo.processInfo.arguments.firstIndex(of: "-snapshotSphere") {
                let args = ProcessInfo.processInfo.arguments
                let mode = (i + 1 < args.count && !args[i + 1].hasPrefix("-")) ? args[i + 1] : nil
                NavigationStack { SphereSnapshotHarness(debugMode: mode) }
                    .preferredColorScheme(.dark)
            } else if let i = ProcessInfo.processInfo.arguments.firstIndex(of: "-snapshotAstro") {
                let args = ProcessInfo.processInfo.arguments
                let screen = (i + 1 < args.count) ? args[i + 1] : "detail"
                AstrologySnapshotHarness(screen: screen)
                    .preferredColorScheme(.dark)
            } else {
                NavigationStack { AstrologyHomeView(store: store) }
                    .preferredColorScheme(.dark)
                    .task { store.loadIfNeeded() }
            }
        }
        .modelContainer(for: SavedChart.self)
    }
}

import Foundation

/// Debug-only (`-snapshotLocation <lat> <lon>`, degrees): a fixed observer position
/// for App Store screenshot runs. With it set, the live-sky chart skips the system
/// location prompt entirely (which otherwise covers every capture in the simulator)
/// and each screenshot is reproducible. Production is untouched — the argument is
/// never present outside a snapshot run. Mirrors the flag of the same name in the
/// sister planetarium app.
enum SnapshotLocation {
    static let coordinate: (latitude: Double, longitude: Double)? = {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-snapshotLocation"),
              i + 2 < args.count,
              let latitude = Double(args[i + 1]),
              let longitude = Double(args[i + 2]) else { return nil }
        return (latitude, longitude)
    }()
}

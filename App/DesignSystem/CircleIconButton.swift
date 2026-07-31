import SwiftUI

/// The luminous circular icon control, ported from Astrolabe's DesignSystem so
/// the sister apps' chrome speaks one language. `CircleIconLabel` is the visual
/// alone — use it as a `Menu` label; `CircleIconButton` wraps it in a Button
/// with the required accessibility label, 44pt target, and selection haptic.
struct CircleIconLabel: View {
    let systemImage: String
    var tint: Color = Theme.astro
    var isActive: Bool = false

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(isActive ? tint : .white.opacity(0.92))
            .frame(width: Theme.controlSize, height: Theme.controlSize)
            .background {
                Circle().fill(.ultraThinMaterial)
                Circle().fill(tint.opacity(isActive ? 0.22 : 0.08))
            }
            .overlay {
                Circle().strokeBorder(tint.opacity(isActive ? 0.9 : 0.45), lineWidth: 1)
            }
            .shadow(color: tint.opacity(isActive ? 0.6 : 0.3), radius: isActive ? 11 : 6)
    }
}

struct CircleIconButton: View {
    let label: String
    let systemImage: String
    var tint: Color = Theme.astro
    var isActive: Bool = false
    let action: () -> Void

    @State private var taps = 0

    var body: some View {
        Button {
            taps += 1
            action()
        } label: {
            CircleIconLabel(systemImage: systemImage, tint: tint, isActive: isActive)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isActive ? .isSelected : [])
        .sensoryFeedback(.selection, trigger: taps)
    }
}

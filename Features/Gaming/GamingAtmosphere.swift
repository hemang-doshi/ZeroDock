import SwiftUI
import FluidGradient

struct GamingAtmosphere: View {
    var colors: [Color]
    var enabled: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        let moving = enabled && !reduceMotion && scenePhase == .active
        Group {
            if !colors.isEmpty {
                if moving {
                    FluidGradient(blobs: colors, highlights: Array(colors.reversed()), speed: 0.15, blur: 0.8)
                } else {
                    LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                }
            }
        }
        .opacity(0.17).allowsHitTesting(false).accessibilityHidden(true)
    }
}

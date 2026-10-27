import SwiftUI

/// Every spacing, size and radius in the UI comes from here. Features never invent numbers.
/// Rules and sources: docs/design-system.md.
enum DockLayout {
    /// Base unit. All spacing is a multiple of it.
    static let unit: CGFloat = 8
    /// Minimum distance from the screen edge on every side.
    static let margin: CGFloat = 24
    /// Space between the two halves.
    static let gutter: CGFloat = 24
    /// Space between stacked groups.
    static let gap: CGFloat = 16
    /// Space between siblings inside a group.
    static let tight: CGFloat = 8
    /// Inset inside a content card.
    static let pad: CGFloat = 16
    /// Standard control height (top bar, secondary actions).
    static let control: CGFloat = 48
    /// Large control height (the main action and its siblings).
    static let controlLarge: CGFloat = 56
    /// Smallest allowed hit region.
    static let minTarget: CGFloat = 44
    /// Outer card radius. Inner shapes use `innerRadius` so corners stay concentric.
    static let radius: CGFloat = 32
    static var innerRadius: CGFloat { radius - pad }
    /// Half a unit: snug insets inside small controls.
    static let inset: CGFloat = 4
    /// Horizontal padding of an unselected switcher segment.
    static let chip: CGFloat = 12
    /// Stroke of the Focus ring, and the matching inset that keeps it inside its frame.
    static let ringStroke: CGFloat = 20
    static var ringInset: CGFloat { ringStroke / 2 }
    /// Height of the Gaming metrics strip.
    static let strip: CGFloat = 80
}

/// Two equal halves split by one vertical axis, as StandBy does. Both halves share height and width.
struct DockHalves<Left: View, Right: View>: View {
    @ViewBuilder var left: Left
    @ViewBuilder var right: Right
    var body: some View {
        HStack(spacing: DockLayout.gutter) {
            left.frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityElement(children: .contain).accessibilityIdentifier("halfLeft")
            right.frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityElement(children: .contain).accessibilityIdentifier("halfRight")
        }
    }
}

extension View {
    /// Content layer: flat, quiet surface. Glass is reserved for controls.
    func contentCard(radius: CGFloat = DockLayout.radius) -> some View {
        background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(.white.opacity(0.06)))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(.white.opacity(0.10), lineWidth: 1))
    }
}

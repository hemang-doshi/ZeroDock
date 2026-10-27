import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Colors that define one mode's mood. Gaming swaps in colors sampled from the cover.
struct ModeTheme {
    var accent: Color
    var accent2: Color
    var backdropTop: Color
    var backdropBottom: Color
}

enum DockTheme {
    static let background = Color(red: 0.043, green: 0.027, blue: 0.063)
    static let surface = Color(red: 0.11, green: 0.08, blue: 0.14)
    static let accent = Color(red: 1.0, green: 0.48, blue: 0.36)
    static let accentSoft = Color(red: 1.0, green: 0.78, blue: 0.34)
    static let gamingAccent = Color(red: 0.36, green: 0.82, blue: 1.0)
    static let secondary = Color(red: 0.72, green: 0.69, blue: 0.78)
    static let stroke = Color.white.opacity(0.12)
    static let gap = DockLayout.gap
    static let radius = DockLayout.radius
    static let label = DockType.label
    static let title = DockType.title

    static func theme(for mode: DockMode, gamingAccent artwork: Color) -> ModeTheme {
        switch mode {
        case .focus:
            ModeTheme(accent: accent, accent2: accentSoft,
                      backdropTop: Color(red: 0.13, green: 0.06, blue: 0.17), backdropBottom: Color(red: 0.04, green: 0.02, blue: 0.07))
        case .ambient:
            ModeTheme(accent: Color(red: 1.0, green: 0.70, blue: 0.42), accent2: Color(red: 1.0, green: 0.55, blue: 0.40),
                      backdropTop: .black, backdropBottom: .black)
        case .gaming:
            ModeTheme(accent: artwork, accent2: artwork.opacity(0.7),
                      backdropTop: Color(red: 0.05, green: 0.06, blue: 0.12), backdropBottom: Color(red: 0.02, green: 0.02, blue: 0.05))
        }
    }
}

/// Type scale tuned for reading from a stand about 60 cm away (assumed ~1.6x a handheld distance):
/// nothing below 18 pt. Apple's iOS default is 17 pt and minimum 11 pt at arm's length.
enum DockType {
    /// Free (OFL) display face for big numerals. Falls back to SF Rounded when it is not bundled.
    static let displayFamily = "Sora"
    static let hasDisplayFont: Bool = {
        #if canImport(UIKit)
        return !UIFont.fontNames(forFamilyName: displayFamily).isEmpty
        #elseif canImport(AppKit)
        return NSFont(name: displayFamily, size: 12) != nil
        #else
        return false
        #endif
    }()

    static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        hasDisplayFont ? .custom(displayFamily, size: size).weight(weight)
                       : .system(size: size, weight: weight, design: .rounded)
    }
    /// Icon glyphs next to text. Sizes still come from here, never inline.
    static func symbol(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font { .system(size: size, weight: weight) }
    static let caption = Font.system(size: 18, weight: .medium, design: .rounded)
    static let label = Font.system(size: 18, weight: .bold, design: .rounded)
    static let control = Font.system(size: 20, weight: .bold, design: .rounded)
    static let body = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let heading = Font.system(size: 30, weight: .bold, design: .rounded)
    static let title = Font.system(size: 40, weight: .bold, design: .rounded)
}

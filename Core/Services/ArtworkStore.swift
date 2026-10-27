import SwiftUI
import Nuke
import Observation

@MainActor @Observable
final class ArtworkStore {
    private(set) var image: CGImage?
    private(set) var colors: [Color] = []
    private(set) var loading = false
    private(set) var accent: Color = DockTheme.gamingAccent

    func load(_ url: URL?) async {
        image = nil
        colors = []
        accent = DockTheme.gamingAccent
        guard let url else { loading = false; return }
        loading = true
        defer { if !Task.isCancelled { loading = false } }
        do {
            let loaded = try await ImagePipeline.shared.image(for: url)
            guard !Task.isCancelled else { return }
            #if os(macOS)
            let cgImage = loaded.cgImage(forProposedRect: nil, context: nil, hints: nil)
            #else
            let cgImage = loaded.cgImage
            #endif
            image = cgImage
            if let cgImage {
                let sampled = Self.sample(cgImage)
                colors = sampled.map { Color(red: $0.0, green: $0.1, blue: $0.2) }
                if let first = sampled.first {
                    accent = Self.legibleAccent(red: first.0, green: first.1, blue: first.2)
                }
            }
        } catch {
            // Unavailable artwork leaves a neutral surface, never a fabricated cover.
        }
    }

    /// Keep the sampled hue but force enough saturation and brightness to read on the dark surface.
    /// Adding one lift to every channel would wash the color out to grey.
    static func legibleAccent(red: Double, green: Double, blue: Double) -> Color {
        let high = max(red, green, blue), low = min(red, green, blue)
        let delta = high - low
        var hue = 0.0
        if delta > 0 {
            if high == red { hue = ((green - blue) / delta).truncatingRemainder(dividingBy: 6) }
            else if high == green { hue = (blue - red) / delta + 2 }
            else { hue = (red - green) / delta + 4 }
            hue /= 6
            if hue < 0 { hue += 1 }
        }
        let saturation = max(high == 0 ? 0 : delta / high, 0.55)
        return Color(hue: hue, saturation: min(1, saturation), brightness: max(high, 0.92))
    }

    private static func sample(_ image: CGImage) -> [(Double, Double, Double)] {
        let size = 24
        var pixels = [UInt8](repeating: 0, count: size * size * 4)
        let drawn = pixels.withUnsafeMutableBytes { bytes -> Bool in
            guard let context = CGContext(data: bytes.baseAddress, width: size, height: size, bitsPerComponent: 8,
                                          bytesPerRow: size * 4, space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: size, height: size))
            return true
        }
        guard drawn else { return [] }
        var groups: [Int: (count: Int, r: Double, g: Double, b: Double)] = [:]
        for offset in stride(from: 0, to: pixels.count, by: 4) {
            let r = Double(pixels[offset]) / 255, g = Double(pixels[offset + 1]) / 255, b = Double(pixels[offset + 2]) / 255
            let brightest = max(r, max(g, b)), darkest = min(r, min(g, b))
            guard pixels[offset + 3] > 200, brightest > 0.15, darkest < 0.9 else { continue }
            let key = (Int(pixels[offset]) / 32) * 64 + (Int(pixels[offset + 1]) / 32) * 8 + Int(pixels[offset + 2]) / 32
            let old = groups[key] ?? (0, 0, 0, 0)
            groups[key] = (old.count + 1, old.r + r, old.g + g, old.b + b)
        }
        let ranked = groups.values.sorted { lhs, rhs in
            func score(_ group: (count: Int, r: Double, g: Double, b: Double)) -> Double {
                Double(group.count) * (0.3 + (max(group.r, max(group.g, group.b)) - min(group.r, min(group.g, group.b))) / Double(group.count))
            }
            return score(lhs) > score(rhs)
        }
        return ranked.prefix(3).map { group in
            (group.r / Double(group.count), group.g / Double(group.count), group.b / Double(group.count))
        }
    }
}

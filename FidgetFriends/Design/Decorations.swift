import SwiftUI

private struct Confetto {
    enum Kind { case star, sparkle, dot, ring }
    let kind: Kind
    let color: Color
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let angle: Double
}

/// Cream background sprinkled with stars, sparkles and dots.
struct WhimsyBackground: View {
    var colors: [Color] = [Palette.cream, Color(hex: 0xFFF6FB), Palette.lilac.opacity(0.7)]
    var density: Double = 1

    private static let confetti: [Confetto] = [
        .init(kind: .sparkle, color: Palette.coral, x: 0.9, y: 0.06, size: 30, angle: 0),
        .init(kind: .star, color: Palette.sunshineDeep, x: 0.08, y: 0.15, size: 22, angle: 12),
        .init(kind: .dot, color: Palette.mint, x: 0.78, y: 0.22, size: 10, angle: 0),
        .init(kind: .sparkle, color: Palette.grape, x: 0.95, y: 0.36, size: 18, angle: 0),
        .init(kind: .ring, color: Palette.sky, x: 0.04, y: 0.42, size: 18, angle: 0),
        .init(kind: .dot, color: Palette.coral, x: 0.22, y: 0.55, size: 8, angle: 0),
        .init(kind: .star, color: Palette.mint, x: 0.93, y: 0.6, size: 20, angle: -15),
        .init(kind: .sparkle, color: Palette.sunshineDeep, x: 0.06, y: 0.72, size: 24, angle: 0),
        .init(kind: .dot, color: Palette.grape, x: 0.6, y: 0.8, size: 9, angle: 0),
        .init(kind: .ring, color: Palette.coral, x: 0.88, y: 0.88, size: 16, angle: 0),
        .init(kind: .star, color: Palette.coral, x: 0.3, y: 0.95, size: 16, angle: 20),
        .init(kind: .sparkle, color: Palette.sky, x: 0.5, y: 0.03, size: 16, angle: 0),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
                ForEach(Array(Self.confetti.enumerated()), id: \.offset) { _, c in
                    shape(for: c)
                        .frame(width: c.size, height: c.size)
                        .rotationEffect(.degrees(c.angle))
                        .position(x: geo.size.width * c.x, y: geo.size.height * c.y)
                        .opacity(0.55 * density)
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func shape(for c: Confetto) -> some View {
        switch c.kind {
        case .star: StarShape(points: 5, innerRatio: 0.5).fill(c.color)
        case .sparkle: StarShape(points: 4, innerRatio: 0.28).fill(c.color)
        case .dot: Circle().fill(c.color)
        case .ring: Circle().strokeBorder(c.color, lineWidth: 3.5)
        }
    }
}

/// Small scattered sparkles to layer over colored banners.
struct SparkleSprinkles: View {
    var color: Color = .white

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array([(0.06, 0.2, 14.0), (0.92, 0.14, 20.0), (0.85, 0.85, 12.0), (0.12, 0.85, 10.0), (0.5, 0.08, 9.0)].enumerated()), id: \.offset) { _, s in
                    StarShape(points: 4, innerRatio: 0.3)
                        .fill(color.opacity(0.85))
                        .frame(width: s.2, height: s.2)
                        .position(x: geo.size.width * s.0, y: geo.size.height * s.1)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension View {
    /// White sticker card with a soft colored edge.
    func stickerCard(border: Color = Palette.lilac, radius: CGFloat = 26, selected: Bool = false) -> some View {
        self
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(selected ? Palette.grape : border, lineWidth: selected ? 4 : 2.5))
            .shadow(color: Palette.grape.opacity(0.12), radius: 10, y: 6)
    }
}

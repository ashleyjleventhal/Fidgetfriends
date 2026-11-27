import SwiftUI

/// Original, code-drawn squishy and fidget illustrations used for the character and toy placeholders.
struct CritterView: View {
    var species: CritterSpecies
    var color: CritterColor
    var eyes: EyeStyle = .dots
    var mouth: MouthStyle = .smile
    var accessory: Accessory = .none
    var cheeks: Bool = true
    var showsShadow: Bool = true

    init(species: CritterSpecies, color: CritterColor, eyes: EyeStyle = .dots, mouth: MouthStyle = .smile,
         accessory: Accessory = .none, cheeks: Bool = true, showsShadow: Bool = true) {
        self.species = species
        self.color = color
        self.eyes = eyes
        self.mouth = mouth
        self.accessory = accessory
        self.cheeks = cheeks
        self.showsShadow = showsShadow
    }

    init(look: CharacterLook, showsShadow: Bool = true) {
        self.init(species: look.species, color: look.color, eyes: look.eyes, mouth: look.mouth,
                  accessory: look.accessory, cheeks: look.cheeks, showsShadow: showsShadow)
    }

    init(item: CollectionItem) {
        self.init(species: item.species, color: item.color, eyes: item.species == .star ? .happy : .dots)
    }

    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            var ctx = context
            ctx.translateBy(x: (size.width - side) / 2, y: (size.height - side) / 2)
            CritterPainter(ctx: ctx, s: side, critter: self).paint()
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

struct StarShape: Shape {
    var points: Int = 5
    var innerRatio: CGFloat = 0.5

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * innerRatio
        var path = Path()
        for i in 0..<(points * 2) {
            let angle = Double(i) * .pi / Double(points) - .pi / 2
            let radius = i.isMultiple(of: 2) ? outer : inner
            let point = CGPoint(x: center.x + CGFloat(cos(angle)) * radius, y: center.y + CGFloat(sin(angle)) * radius)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

private struct FaceLayout {
    var eyeY: CGFloat = 0.56
    var eyeDX: CGFloat = 0.13
    var eyeScale: CGFloat = 1
    var mouthY: CGFloat = 0.66
    var headTop: CGFloat = 0.26
}

private struct CritterPainter {
    let ctx: GraphicsContext
    let s: CGFloat
    let critter: CritterView

    private var line: CGFloat { s * 0.022 }
    private var outline: GraphicsContext.Shading { .color(critter.color.shade) }
    private var bodyFill: GraphicsContext.Shading {
        .linearGradient(Gradient(colors: critter.color.gradient), startPoint: pt(0.5, 0.15), endPoint: pt(0.5, 0.95))
    }
    private var inkShade: GraphicsContext.Shading { .color(Palette.ink) }

    private func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }
    private func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
        CGRect(x: x * s, y: y * s, width: w * s, height: h * s)
    }
    private func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path {
        Path(ellipseIn: rect(cx - r, cy - r, r * 2, r * 2))
    }
    private func mx(_ x: CGFloat, _ flip: Bool) -> CGFloat { flip ? 1 - x : x }
    private func stroke(_ path: Path, _ shading: GraphicsContext.Shading, width: CGFloat? = nil) {
        ctx.stroke(path, with: shading, style: StrokeStyle(lineWidth: width ?? line, lineCap: .round, lineJoin: .round))
    }
    private func fillStroke(_ path: Path, _ shading: GraphicsContext.Shading? = nil, outline custom: GraphicsContext.Shading? = nil) {
        ctx.fill(path, with: shading ?? bodyFill)
        stroke(path, custom ?? outline)
    }

    private var layout: FaceLayout {
        switch critter.species {
        case .frog: return FaceLayout(eyeY: 0.34, eyeDX: 0.17, eyeScale: 1.15, mouthY: 0.6, headTop: 0.22)
        case .star: return FaceLayout(eyeY: 0.54, eyeDX: 0.1, eyeScale: 0.9, mouthY: 0.63, headTop: 0.16)
        default: return FaceLayout()
        }
    }

    func paint() {
        if critter.showsShadow {
            ctx.fill(Path(ellipseIn: rect(0.2, 0.86, 0.6, 0.08)), with: .color(Palette.ink.opacity(0.10)))
        }
        switch critter.species {
        case .popIt: paintPopIt()
        case .cube: paintCube()
        case .spinner: paintSpinner()
        default:
            paintSquishy()
            paintAccessory()
        }
    }

    // MARK: Squishys

    private func paintSquishy() {
        let species = critter.species
        let pink = GraphicsContext.Shading.color(Palette.blush.opacity(0.65))
        switch species {
        case .cat:
            for flip in [false, true] {
                var ear = Path()
                ear.move(to: pt(mx(0.19, flip), 0.44))
                ear.addLine(to: pt(mx(0.23, flip), 0.12))
                ear.addLine(to: pt(mx(0.46, flip), 0.3))
                ear.closeSubpath()
                fillStroke(ear)
                var inner = Path()
                inner.move(to: pt(mx(0.25, flip), 0.37))
                inner.addLine(to: pt(mx(0.265, flip), 0.21))
                inner.addLine(to: pt(mx(0.38, flip), 0.3))
                inner.closeSubpath()
                ctx.fill(inner, with: pink)
            }
        case .bunny:
            for flip in [false, true] {
                let r = rect(flip ? 0.56 : 0.28, 0.02, 0.16, 0.4)
                fillStroke(Path(roundedRect: r, cornerRadius: 0.08 * s))
                ctx.fill(Path(roundedRect: r.insetBy(dx: 0.045 * s, dy: 0.07 * s), cornerRadius: 0.035 * s), with: pink)
            }
        case .bear:
            for flip in [false, true] {
                fillStroke(circle(mx(0.26, flip), 0.3, 0.1))
                ctx.fill(circle(mx(0.26, flip), 0.3, 0.05), with: pink)
            }
        case .axolotl:
            let gillFill = GraphicsContext.Shading.color(Color(hex: 0xFF8FB8))
            let gillLine = GraphicsContext.Shading.color(Color(hex: 0xE0558F))
            for flip in [false, true] {
                for angle in [-0.55, 0.0, 0.55] {
                    let base = Path(roundedRect: CGRect(x: -0.17 * s, y: -0.035 * s, width: 0.17 * s, height: 0.07 * s), cornerRadius: 0.035 * s)
                    let direction = flip ? -1.0 : 1.0
                    let transform = CGAffineTransform(translationX: mx(0.2, flip) * s, y: 0.45 * s)
                        .scaledBy(x: CGFloat(direction), y: 1)
                        .rotated(by: CGFloat(angle) + 0.35)
                    fillStroke(base.applying(transform), gillFill, outline: gillLine)
                }
            }
        default:
            break
        }

        let body: Path
        switch species {
        case .star:
            body = StarShape(points: 5, innerRatio: 0.58).path(in: rect(0.06, 0.1, 0.88, 0.84))
        case .frog:
            body = UnevenRoundedRectangle(cornerRadii: .init(topLeading: 0.3 * s, bottomLeading: 0.2 * s, bottomTrailing: 0.2 * s, topTrailing: 0.3 * s), style: .continuous)
                .path(in: rect(0.1, 0.3, 0.8, 0.58))
        default:
            body = UnevenRoundedRectangle(cornerRadii: .init(topLeading: 0.34 * s, bottomLeading: 0.2 * s, bottomTrailing: 0.2 * s, topTrailing: 0.34 * s), style: .continuous)
                .path(in: rect(0.14, 0.26, 0.72, 0.62))
        }
        fillStroke(body)

        if species != .star {
            ctx.fill(Path(ellipseIn: rect(0.32, 0.64, 0.36, 0.2)), with: .color(.white.opacity(0.35)))
        }
        ctx.fill(Path(ellipseIn: rect(species == .star ? 0.36 : 0.24, species == .star ? 0.3 : 0.33, 0.13, 0.07)), with: .color(.white.opacity(0.6)))

        if species == .frog {
            for flip in [false, true] {
                fillStroke(circle(mx(0.33, flip), 0.34, 0.12))
                ctx.fill(circle(mx(0.33, flip), 0.34, 0.085), with: .color(.white.opacity(0.85)))
            }
        }
        if species == .blob {
            stroke(Path { p in p.move(to: pt(0.5, 0.27)); p.addLine(to: pt(0.5, 0.2)) }, .color(Palette.mintDeep))
            for flip in [false, true] {
                let leaf = Path(ellipseIn: CGRect(x: -0.06 * s, y: -0.03 * s, width: 0.12 * s, height: 0.06 * s))
                    .applying(CGAffineTransform(translationX: (flip ? 0.555 : 0.445) * s, y: 0.19 * s).rotated(by: flip ? -0.5 : 0.5))
                fillStroke(leaf, .color(Color(hex: 0x7EDDB0)), outline: .color(Palette.mintDeep))
            }
        }
        paintFace(layout)
    }

    private func paintFace(_ f: FaceLayout) {
        if critter.cheeks {
            for flip in [false, true] {
                let cx = mx(0.5 - f.eyeDX - 0.045, flip)
                ctx.fill(Path(ellipseIn: rect(cx - 0.05, f.eyeY + 0.055, 0.1, 0.055)), with: .color(Palette.blush.opacity(0.7)))
            }
        }
        for (index, ex) in [0.5 - f.eyeDX, 0.5 + f.eyeDX].enumerated() {
            var style = critter.eyes
            if style == .wink { style = index == 1 ? .happy : .dots }
            paintEye(style, x: ex, y: f.eyeY, r: 0.042 * f.eyeScale)
        }
        paintMouth(y: f.mouthY)
    }

    private func paintEye(_ style: EyeStyle, x: CGFloat, y: CGFloat, r: CGFloat) {
        let white = GraphicsContext.Shading.color(.white)
        switch style {
        case .dots, .wink:
            ctx.fill(circle(x, y, r), with: inkShade)
            ctx.fill(circle(x + r * 0.35, y - r * 0.35, r * 0.35), with: white)
        case .sparkle:
            ctx.fill(Path(ellipseIn: rect(x - r * 1.15, y - r * 1.45, r * 2.3, r * 2.9)), with: inkShade)
            ctx.fill(circle(x + r * 0.35, y - r * 0.55, r * 0.45), with: white)
            ctx.fill(circle(x - r * 0.4, y + r * 0.5, r * 0.2), with: white)
        case .happy:
            var p = Path()
            p.move(to: pt(x - r * 1.1, y + r * 0.4))
            p.addQuadCurve(to: pt(x + r * 1.1, y + r * 0.4), control: pt(x, y - r * 1.4))
            stroke(p, inkShade, width: line * 1.3)
        case .sleepy:
            var p = Path()
            p.move(to: pt(x - r * 1.1, y - r * 0.2))
            p.addQuadCurve(to: pt(x + r * 1.1, y - r * 0.2), control: pt(x, y + r * 1.2))
            stroke(p, inkShade, width: line * 1.3)
        }
    }

    private func paintMouth(y: CGFloat) {
        let w: CGFloat = 0.055
        let tongue = GraphicsContext.Shading.color(Color(hex: 0xFF6F91))
        switch critter.mouth {
        case .smile:
            var p = Path()
            p.move(to: pt(0.5 - w, y))
            p.addQuadCurve(to: pt(0.5 + w, y), control: pt(0.5, y + w * 1.3))
            stroke(p, inkShade, width: line * 1.1)
        case .grin:
            var p = Path()
            p.move(to: pt(0.5 - w * 1.1, y - 0.008))
            p.addQuadCurve(to: pt(0.5 + w * 1.1, y - 0.008), control: pt(0.5, y + w * 2))
            p.closeSubpath()
            ctx.fill(p, with: inkShade)
            ctx.fill(Path(ellipseIn: rect(0.5 - w * 0.5, y + w * 0.35, w, w * 0.55)), with: tongue)
        case .tongue:
            ctx.fill(Path(roundedRect: rect(0.5 - 0.024, y + 0.005, 0.048, 0.055), cornerRadius: 0.024 * s), with: tongue)
            var p = Path()
            p.move(to: pt(0.5 - w, y))
            p.addQuadCurve(to: pt(0.5 + w, y), control: pt(0.5, y + w * 1.0))
            stroke(p, inkShade, width: line * 1.1)
        case .oh:
            ctx.fill(Path(ellipseIn: rect(0.5 - 0.022, y - 0.012, 0.044, 0.052)), with: inkShade)
        case .kitty:
            var p = Path()
            p.move(to: pt(0.5 - w, y))
            p.addQuadCurve(to: pt(0.5, y), control: pt(0.5 - w / 2, y + w))
            p.addQuadCurve(to: pt(0.5 + w, y), control: pt(0.5 + w / 2, y + w))
            stroke(p, inkShade, width: line * 1.1)
        }
    }

    private func paintAccessory() {
        let f = layout
        let top = f.headTop
        switch critter.accessory {
        case .none:
            break
        case .crown:
            let y0 = top + 0.03
            var p = Path()
            p.move(to: pt(0.38, y0))
            p.addLine(to: pt(0.36, y0 - 0.12))
            p.addLine(to: pt(0.44, y0 - 0.06))
            p.addLine(to: pt(0.5, y0 - 0.15))
            p.addLine(to: pt(0.56, y0 - 0.06))
            p.addLine(to: pt(0.64, y0 - 0.12))
            p.addLine(to: pt(0.62, y0))
            p.closeSubpath()
            fillStroke(p, .linearGradient(Gradient(colors: [Color(hex: 0xFFF1A6), Color(hex: 0xFFCB2E)]), startPoint: pt(0.5, y0 - 0.15), endPoint: pt(0.5, y0)), outline: .color(Color(hex: 0xD49E00)))
            ctx.fill(circle(0.5, y0 - 0.04, 0.018), with: .color(Palette.coralDeep))
            ctx.fill(circle(0.42, y0 - 0.03, 0.012), with: .color(Palette.mintDeep))
            ctx.fill(circle(0.58, y0 - 0.03, 0.012), with: .color(Palette.skyDeep))
        case .bow:
            let c = pt(0.7, top + 0.05)
            let bowFill = GraphicsContext.Shading.color(Color(hex: 0xFF6F91))
            let bowLine = GraphicsContext.Shading.color(Color(hex: 0xD94470))
            for flip in [-1.0, 1.0] {
                var wing = Path()
                wing.move(to: c)
                wing.addLine(to: CGPoint(x: c.x + CGFloat(flip) * 0.1 * s, y: c.y - 0.06 * s))
                wing.addLine(to: CGPoint(x: c.x + CGFloat(flip) * 0.1 * s, y: c.y + 0.06 * s))
                wing.closeSubpath()
                fillStroke(wing, bowFill, outline: bowLine)
            }
            fillStroke(Path(ellipseIn: CGRect(x: c.x - 0.03 * s, y: c.y - 0.03 * s, width: 0.06 * s, height: 0.06 * s)), bowFill, outline: bowLine)
        case .flower:
            let cx: CGFloat = 0.7, cy = top + 0.04
            for i in 0..<5 {
                let a = Double(i) / 5 * 2 * .pi
                let petal = circle(cx + CGFloat(cos(a)) * 0.045, cy + CGFloat(sin(a)) * 0.045, 0.035)
                fillStroke(petal, .color(.white), outline: .color(Color(hex: 0xFF8FB1)))
            }
            fillStroke(circle(cx, cy, 0.03), .color(Color(hex: 0xFFD23F)), outline: .color(Color(hex: 0xE0A400)))
        case .star:
            fillStroke(StarShape(points: 5, innerRatio: 0.5).path(in: rect(0.61, top - 0.07, 0.18, 0.18)), .color(Color(hex: 0xFFD23F)), outline: .color(Color(hex: 0xD49E00)))
        case .glasses:
            let r = 0.075 * f.eyeScale
            let frame = GraphicsContext.Shading.color(Palette.grapeDeep)
            for x in [0.5 - f.eyeDX, 0.5 + f.eyeDX] {
                ctx.fill(circle(x, f.eyeY, r), with: .color(.white.opacity(0.25)))
                stroke(circle(x, f.eyeY, r), frame, width: line * 1.2)
            }
            stroke(Path { p in
                p.move(to: pt(0.5 - f.eyeDX + r, f.eyeY))
                p.addQuadCurve(to: pt(0.5 + f.eyeDX - r, f.eyeY), control: pt(0.5, f.eyeY - 0.03))
            }, frame, width: line * 1.2)
        case .headphones:
            let band = GraphicsContext.Shading.color(Palette.grape)
            stroke(Path { p in
                p.move(to: pt(0.15, top + 0.24))
                p.addQuadCurve(to: pt(0.85, top + 0.24), control: pt(0.5, top - 0.24))
            }, band, width: line * 2.6)
            for flip in [false, true] {
                fillStroke(Path(roundedRect: rect(mx(0.07, flip) - (flip ? 0.13 : 0), top + 0.16, 0.13, 0.22), cornerRadius: 0.06 * s),
                           .color(Color(hex: 0xA77BFF)), outline: .color(Palette.grapeDeep))
            }
        case .partyHat:
            var p = Path()
            p.move(to: pt(0.4, top + 0.04))
            p.addLine(to: pt(0.6, top + 0.04))
            p.addLine(to: pt(0.53, top - 0.17))
            p.closeSubpath()
            fillStroke(p, .linearGradient(Gradient(colors: [Color(hex: 0x7FCBFF), Color(hex: 0x6938C5)]), startPoint: pt(0.5, top - 0.17), endPoint: pt(0.5, top + 0.04)), outline: .color(Palette.grapeDeep))
            ctx.fill(circle(0.49, top - 0.04, 0.014), with: .color(Color(hex: 0xFFD23F)))
            ctx.fill(circle(0.53, top - 0.0, 0.014), with: .color(Color(hex: 0xFF8FB1)))
            fillStroke(circle(0.53, top - 0.18, 0.03), .color(Color(hex: 0xFF936F)), outline: .color(Color(hex: 0xD9603A)))
        }
    }

    // MARK: Fidgets

    private func paintPopIt() {
        let board = rect(0.13, 0.17, 0.74, 0.72)
        fillStroke(Path(roundedRect: board, cornerRadius: 0.15 * s), .color(.white), outline: outline)
        let rainbow: [[Color]] = [[Color(hex: 0xFFC2D9), Color(hex: 0xFF8FB8)], [Color(hex: 0xFFF0A6), Color(hex: 0xFFD23F)],
                                  [Color(hex: 0xC9F5E4), Color(hex: 0x5FD6AE)], [Color(hex: 0xD3ECFF), Color(hex: 0x6CBCFF)]]
        for row in 0..<4 {
            let colors = critter.color == .rainbow ? rainbow[row] : critter.color.gradient
            for col in 0..<4 {
                let cx = 0.13 + 0.74 * (CGFloat(col) + 0.5) / 4
                let cy = 0.17 + 0.72 * (CGFloat(row) + 0.5) / 4
                let bubble = circle(cx, cy, 0.068)
                ctx.fill(bubble, with: .radialGradient(Gradient(colors: colors), center: pt(cx - 0.02, cy - 0.02), startRadius: 0, endRadius: 0.08 * s))
                stroke(bubble, .color(Palette.ink.opacity(0.18)), width: line * 0.6)
                ctx.fill(circle(cx - 0.022, cy - 0.025, 0.016), with: .color(.white.opacity(0.8)))
            }
        }
    }

    private func paintCube() {
        let light = critter.color.gradient.first ?? .white
        var side = Path()
        side.move(to: pt(0.78, 0.3)); side.addLine(to: pt(0.88, 0.2)); side.addLine(to: pt(0.88, 0.76)); side.addLine(to: pt(0.78, 0.86)); side.closeSubpath()
        fillStroke(side, .color(critter.color.shade.opacity(0.75)))
        var top = Path()
        top.move(to: pt(0.16, 0.3)); top.addLine(to: pt(0.26, 0.2)); top.addLine(to: pt(0.88, 0.2)); top.addLine(to: pt(0.78, 0.3)); top.closeSubpath()
        fillStroke(top, .color(light))
        fillStroke(Path(roundedRect: rect(0.16, 0.3, 0.62, 0.56), cornerRadius: 0.06 * s))
        let buttons: [Color] = [Color(hex: 0xFF8FB8), Color(hex: 0xFFD23F), Color(hex: 0x6CBCFF)]
        for (i, c) in buttons.enumerated() {
            let b = circle(0.3 + CGFloat(i) * 0.17, 0.43, 0.05)
            fillStroke(b, .color(c), outline: .color(Palette.ink.opacity(0.3)))
            ctx.fill(circle(0.285 + CGFloat(i) * 0.17, 0.415, 0.014), with: .color(.white.opacity(0.8)))
        }
        fillStroke(circle(0.33, 0.68, 0.08), .color(Palette.ink.opacity(0.8)), outline: .color(Palette.ink))
        ctx.fill(circle(0.31, 0.66, 0.025), with: .color(.white.opacity(0.5)))
        fillStroke(Path(roundedRect: rect(0.5, 0.63, 0.2, 0.1), cornerRadius: 0.05 * s), .color(.white), outline: .color(Palette.ink.opacity(0.3)))
        fillStroke(circle(0.65, 0.68, 0.04), .color(Color(hex: 0x5FD6AE)), outline: .color(Palette.mintDeep))
    }

    private func paintSpinner() {
        let c = (x: CGFloat(0.5), y: CGFloat(0.53))
        let arms: [Double] = [-90, 30, 150]
        var hub = Path()
        for (i, deg) in arms.enumerated() {
            let a = deg * .pi / 180
            let p = pt(c.x + CGFloat(cos(a)) * 0.24, c.y + CGFloat(sin(a)) * 0.24)
            if i == 0 { hub.move(to: p) } else { hub.addLine(to: p) }
        }
        hub.closeSubpath()
        ctx.fill(hub, with: bodyFill)
        stroke(hub, outline, width: 0.2 * s)
        ctx.fill(hub, with: bodyFill)
        for deg in arms {
            let a = deg * .pi / 180
            let x = c.x + CGFloat(cos(a)) * 0.24, y = c.y + CGFloat(sin(a)) * 0.24
            fillStroke(circle(x, y, 0.15))
            fillStroke(circle(x, y, 0.065), .color(.white.opacity(0.9)))
            ctx.fill(circle(x - 0.02, y - 0.02, 0.018), with: .color(critter.color.shade.opacity(0.4)))
        }
        fillStroke(circle(c.x, c.y, 0.09), .color(Color(hex: 0xFFD23F)), outline: .color(Color(hex: 0xD49E00)))
        ctx.fill(circle(c.x - 0.025, c.y - 0.025, 0.022), with: .color(.white.opacity(0.8)))
    }
}

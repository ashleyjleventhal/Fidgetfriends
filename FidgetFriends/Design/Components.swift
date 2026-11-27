import SwiftUI

func counted(_ count: Int, singular: String, plural: String) -> String {
    "\(count) \(count == 1 ? singular : plural)"
}

struct ChunkyButtonStyle: ButtonStyle {
    var color: Color = Palette.grape
    var shadow: Color = Palette.grapeDeep
    var foreground: Color = .white
    var fullWidth = true
    var compact = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        return configuration.label
            .font(.fun(compact ? .headline : .title3, weight: .heavy))
            .foregroundStyle(foreground)
            .multilineTextAlignment(.center)
            .padding(.vertical, compact ? 14 : 16)
            .padding(.horizontal, compact ? 12 : 22)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: 56)
            .background(shape.fill(color).overlay(shape.strokeBorder(.white.opacity(0.35), lineWidth: 2)))
            .background(shape.fill(shadow).offset(y: configuration.isPressed ? 2 : 6))
            .offset(y: configuration.isPressed ? 4 : 0)
            .opacity(isEnabled ? 1 : 0.45)
            .contentShape(shape)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ChunkyButtonStyle {
    static var chunky: ChunkyButtonStyle { ChunkyButtonStyle() }
    static func chunky(_ color: Color, shadow: Color, foreground: Color = .white, fullWidth: Bool = true, compact: Bool = false) -> ChunkyButtonStyle {
        ChunkyButtonStyle(color: color, shadow: shadow, foreground: foreground, fullWidth: fullWidth, compact: compact)
    }
}

struct FunChip: View {
    let title: String
    var systemImage: String?
    let isOn: Bool
    var color: Color = Palette.grape
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .font(.fun(.headline))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .foregroundStyle(isOn ? .white : Palette.ink)
            .background(Capsule().fill(isOn ? color : .white))
            .overlay(Capsule().strokeBorder(isOn ? color : Palette.lilac, lineWidth: 2.5))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

struct FunTextField: View {
    let placeholder: String
    @Binding var text: String
    var maxLength = 24
    var axis: Axis = .horizontal

    var body: some View {
        TextField(placeholder, text: $text, prompt: Text(placeholder).foregroundStyle(Palette.inkSoft), axis: axis)
            .accessibilityLabel(placeholder)
            .autocorrectionDisabled()
            .font(.fun(.title3))
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Palette.lilac, lineWidth: 2.5))
            .onChange(of: text) { oldValue, newValue in
                let name: String
                if axis == .vertical, newValue.contains(where: \.isNewline) {
                    if oldValue.count == maxLength, newValue.filter({ !$0.isNewline }) == oldValue {
                        name = oldValue
                    } else {
                        name = newValue.split(whereSeparator: \.isWhitespace).joined(separator: " ")
                    }
                } else {
                    name = newValue
                }
                let limited = String(name.prefix(maxLength))
                if limited != newValue { text = limited }
            }
    }
}

struct SearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(Palette.grape)
                .accessibilityHidden(true)
            TextField("Find a squishy or fidget", text: $text,
                      prompt: Text("Find a squishy or fidget").foregroundStyle(Palette.inkSoft))
                .font(.fun(.body, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .accessibilityLabel("Find a squishy or fidget")
                .submitLabel(.search)
                .accessibilityIdentifier("shelf.search")
            if !text.isEmpty {
                Button { text = "" } label: { Image(systemName: "xmark.circle.fill") }
                    .foregroundStyle(Palette.inkSoft)
                    .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(Capsule().fill(Palette.lilac.opacity(0.85)))
    }
}

struct SectionLabel: View {
    let text: String
    var trailing: String?

    var body: some View {
        HStack {
            Text(text).font(.fun(.title3, weight: .heavy)).foregroundStyle(Palette.ink)
            Spacer()
            if let trailing { Text(trailing).font(.fun(.caption)).foregroundStyle(Palette.inkSoft) }
        }
    }
}

struct BuddyAvatar: View {
    let look: CharacterLook
    var size: CGFloat = 56

    var body: some View {
        CritterView(look: look, showsShadow: false)
            .padding(size * 0.08)
            .frame(width: size, height: size)
            .background(Circle().fill(look.color.pastel))
            .overlay(Circle().strokeBorder(.white, lineWidth: 3))
            .accessibilityHidden(true)
    }
}

/// A toy's picture: the kid's own photo if they added one, otherwise its illustration.
struct ItemThumbnail: View {
    let item: CollectionItem
    var photo: UIImage?

    var body: some View {
        ZStack {
            LinearGradient(colors: [item.color.pastel, item.color.pastel.opacity(0.6)], startPoint: .top, endPoint: .bottom)
            if let photo {
                Image(uiImage: photo).resizable().scaledToFill()
            } else if let art = item.artName {
                Image(art).resizable().scaledToFit().padding(10)
            } else {
                CritterView(item: item).padding(12)
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }
}

/// Simple wrapping layout for chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(width: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(width: bounds.width, subviews: subviews)
        for (index, origin) in result.origins.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, maxX: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return (CGSize(width: maxX, height: y + rowHeight), origins)
    }
}

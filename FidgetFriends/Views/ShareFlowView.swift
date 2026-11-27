import SwiftUI

/// Renders a toy-only collection picture on-device, asks a grown-up to pass a gate,
/// then hands the picture to the iOS share sheet. Nothing is sent automatically.
struct ShareFlowView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    let items: [CollectionItem]

    private enum Stage { case preview, gate, ready }
    @State private var stage: Stage = .preview
    @State private var poster: UIImage?

    var body: some View {
        NavigationStack {
            Group {
                switch stage {
                case .preview, .ready:
                    previewStage
                case .gate:
                    ParentGateView { withAnimation { stage = .ready } } onCancel: { withAnimation { stage = .preview } }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("share.viewport")
            .background(WhimsyBackground(colors: [Palette.cream, Palette.skyPastel.opacity(0.7)], density: 0.7))
            .navigationTitle("Share my collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }.font(.fun(.body)).accessibilityIdentifier("share.close")
                }
            }
        }
        .task { render() }
    }

    private var previewStage: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    posterPreview(maxHeight: min(520, geometry.size.height * 0.68))

                    if let note = SharePoster.truncationNote(shown: featured.count, total: items.count) {
                        Label("\(note). The picture fits up to \(SharePoster.maxItems) toys.", systemImage: "info.circle.fill")
                            .font(.fun(.subheadline, weight: .semibold))
                            .foregroundStyle(Palette.coralDeep)
                            .accessibilityIdentifier("share.truncated")
                    }

                    Label("Only toy pictures and names go in. Your nickname and private notes stay out.", systemImage: "lock.shield.fill")
                        .font(.fun(.subheadline, weight: .semibold))
                        .foregroundStyle(Palette.grape)
                        .multilineTextAlignment(.leading)
                }
                .padding(20)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                shareActions
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                    .frame(maxWidth: 640)
                    .frame(maxWidth: .infinity)
                    .background(.bar)
            }
        }
    }

    private func posterPreview(maxHeight: CGFloat) -> some View {
        Group {
            if let poster {
                Image(uiImage: poster)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: Palette.grape.opacity(0.25), radius: 16, y: 8)
                    .accessibilityLabel("Collection picture with \(featured.count) toys")
                    .accessibilityIdentifier("share.poster")
            } else {
                ProgressView().frame(height: min(300, maxHeight))
            }
        }
        .frame(maxHeight: maxHeight)
    }

    @ViewBuilder
    private var shareActions: some View {
        if stage == .ready, let poster {
            VStack(spacing: 10) {
                ShareLink(item: Image(uiImage: poster), preview: SharePreview("My squishy squad", image: Image(uiImage: poster))) {
                    Label("Choose how to send", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.chunky(Palette.grape, shadow: Palette.grapeDeep))
                .accessibilityIdentifier("share.open")
                Text("Pick Messages to send it to a friend. Nothing is sent until you tap Send.")
                    .font(.fun(.footnote, weight: .semibold))
                    .foregroundStyle(Palette.inkSoft)
                    .multilineTextAlignment(.center)
            }
        } else {
            Button { withAnimation { stage = .gate } } label: {
                Label("Ask a grown-up to send it", systemImage: "person.2.fill")
            }
            .buttonStyle(.chunky(Palette.coral, shadow: Palette.coralDeep))
            .disabled(poster == nil)
            .accessibilityIdentifier("share.continue")
        }
    }

    private var featured: [CollectionItem] { SharePoster.featured(from: items) }

    @MainActor
    private func render() {
        guard poster == nil else { return }
        let photos = Dictionary(uniqueKeysWithValues: featured.compactMap { item in store.image(for: item).map { (item.id, $0) } })
        let renderer = ImageRenderer(content: SharePoster(items: featured, totalCount: items.count, photos: photos))
        renderer.scale = max(displayScale, 2)
        poster = renderer.uiImage
    }
}

struct SharePoster: View {
    static let maxItems = 12
    static let size = CGSize(width: 600, height: 760)

    let items: [CollectionItem]
    let totalCount: Int
    let photos: [UUID: UIImage]

    static func truncationNote(shown: Int, total: Int) -> String? {
        shown < total ? "Showing \(shown) of \(total) · favorites first" : nil
    }

    /// Favorites first, then newest, capped so the picture stays readable.
    static func featured(from items: [CollectionItem]) -> [CollectionItem] {
        Array((items.filter(\.isFavorite) + items.filter { !$0.isFavorite }).prefix(maxItems))
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Palette.grape, Color(hex: 0x8C5BE0), Palette.coral], startPoint: .topLeading, endPoint: .bottomTrailing)
            SparkleSprinkles(color: Palette.sunshine)
            VStack(spacing: 16) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("My squishy squad!")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("\(totalCount) tiny besties on my happy shelf")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.sunshine)
                        if let note = Self.truncationNote(shown: items.count, total: totalCount) {
                            Text(note)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                    Spacer(minLength: 0)
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                    ForEach(items) { item in
                        VStack(spacing: 6) {
                            ItemThumbnail(item: item, photo: photos[item.id])
                                .frame(height: items.count > 9 ? 92 : 120)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            Text(item.name)
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                .foregroundStyle(Palette.ink)
                                .lineLimit(1)
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white))
                        .overlay(alignment: .topTrailing) {
                            if item.isFavorite {
                                Image(systemName: "heart.fill").font(.system(size: 14, weight: .bold)).foregroundStyle(Palette.coralDeep)
                                    .padding(6).background(Circle().fill(.white)).offset(x: 4, y: -4)
                            }
                        }
                    }
                }
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    StarShape().fill(Palette.sunshine).frame(width: 18, height: 18)
                    Text("Made with Fidget Friends")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding(28)
        }
        .frame(width: Self.size.width, height: Self.size.height)
    }
}

/// A grown-up check before anything leaves the app. This is a speed bump for young kids, not legal consent.
struct ParentGateView: View {
    var onPass: () -> Void
    var onCancel: () -> Void

    private static let words = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]
    @State private var a = Int.random(in: 3...9)
    @State private var b = Int.random(in: 3...9)
    @State private var entry = ""
    @State private var wrong = false

    var body: some View {
        VStack(spacing: 12) {
            ViewThatFits(in: .vertical) {
                fields(compact: false)
                fields(compact: true)
                ScrollView {
                    fields(compact: true)
                        .frame(maxWidth: .infinity)
                }
            }
            actions
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: 420)
        .padding(20)
    }

    private func fields(compact: Bool) -> some View {
        let badgeSize: CGFloat = compact ? 56 : 84
        return VStack(spacing: compact ? 10 : 18) {
            Image(systemName: "person.2.fill")
                .font(.system(size: compact ? 28 : 40, weight: .bold))
                .foregroundStyle(Palette.grape)
                .frame(width: badgeSize, height: badgeSize)
                .background(Circle().fill(Palette.lilac))
            Text("Grown-ups only")
                .font(.fun(.largeTitle, weight: .black))
                .foregroundStyle(Palette.ink)
            ZStack {
                Text("To send this picture, a grown-up please answer:")
                    .foregroundStyle(Palette.inkSoft)
                    .opacity(wrong ? 0 : 1)
                    .accessibilityHidden(wrong)
                Text("Not quite — try a new one.")
                    .foregroundStyle(Palette.coralDeep)
                    .opacity(wrong ? 1 : 0)
                    .accessibilityHidden(!wrong)
            }
            .font(.fun(.headline, weight: .semibold))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            Text("What is \(Self.words[a]) times \(Self.words[b])?")
                .font(.fun(.title2, weight: .heavy))
                .foregroundStyle(Palette.grape)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("gate.question")
            Text(entry.isEmpty ? " " : entry)
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: 220, minHeight: compact ? 54 : 64)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(wrong ? Palette.coralDeep : Palette.lilac, lineWidth: 3))
                .accessibilityLabel("Answer \(entry)")
                .accessibilityIdentifier("gate.entry")
            keypad(compact: compact)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button("Back", action: onCancel)
                .buttonStyle(.chunky(.white, shadow: Palette.lilac, foreground: Palette.grape))
                .accessibilityIdentifier("gate.cancel")
            Button("Check", action: check)
                .buttonStyle(.chunky(Palette.grape, shadow: Palette.grapeDeep))
                .disabled(entry.isEmpty)
                .accessibilityIdentifier("gate.submit")
        }
    }

    private func keypad(compact: Bool) -> some View {
        let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "⌫", "0", ""]
        let keyHeight: CGFloat = compact ? 48 : 60
        return LazyVGrid(columns: Array(repeating: GridItem(.fixed(76), spacing: 12), count: 3), spacing: compact ? 8 : 12) {
            ForEach(Array(keys.enumerated()), id: \.offset) { _, key in
                if key.isEmpty {
                    Color.clear.frame(height: keyHeight)
                } else {
                    Button {
                        if key == "⌫" { entry = String(entry.dropLast()) } else if entry.count < 3 { entry += key }
                    } label: {
                        Text(key).font(.fun(.title2, weight: .heavy)).frame(width: 76, height: keyHeight)
                            .foregroundStyle(Palette.ink)
                            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white))
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.lilac, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(key == "⌫" ? "Delete" : key)
                    .accessibilityIdentifier("gate.key.\(key == "⌫" ? "delete" : key)")
                }
            }
        }
    }

    private func check() {
        if Int(entry) == a * b {
            onPass()
        } else {
            wrong = true
            entry = ""
            a = Int.random(in: 3...9)
            b = Int.random(in: 3...9)
        }
    }
}

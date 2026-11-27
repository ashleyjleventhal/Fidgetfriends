import SwiftUI

struct ShelfScreen: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let favoritesOnly: Bool
    /// When set (wide iPad), tapping a toy selects it for the side panel instead of pushing a page.
    var selection: Binding<UUID?>?
    let onAddToy: () -> Void

    @State private var filter: CollectionFilter = .all
    @State private var search = ""
    @State private var showingShare = false

    private var activeFilter: CollectionFilter { favoritesOnly ? .faves : filter }
    private var visible: [CollectionItem] { store.items.filtered(activeFilter, search: search) }
    private var needsFirstToy: Bool { !favoritesOnly && store.items.isEmpty }
    private var toyCountLabel: String {
        if favoritesOnly {
            return "\(counted(store.favoriteCount, singular: "fave", plural: "faves"))!"
        }
        let squishies = counted(store.squishyCount, singular: "squishy", plural: "squishies")
        let fidgets = counted(store.fidgetCount, singular: "fidget", plural: "fidgets")
        return "\(squishies) & \(fidgets)"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                banner
                if !needsFirstToy {
                    SearchField(text: $search)
                    if !favoritesOnly { filterChips }
                }
                content
                if !store.items.isEmpty {
                    Text("\(visible.count) of \(store.items.count) shown")
                        .font(.fun(.footnote))
                        .foregroundStyle(Palette.inkSoft)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.immediately)
        .background(WhimsyBackground())
        .safeAreaInset(edge: .bottom) {
            if !needsFirstToy { bottomButtons }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: UUID.self) { id in ItemDetailScreen(itemID: id) }
        .sheet(isPresented: $showingShare) { ShareFlowView(items: store.items) }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(favoritesOnly ? "My favorites" : "My happy shelf")
                .font(.system(.largeTitle, design: .rounded).weight(.black))
                .foregroundStyle(Palette.ink)
                .accessibilityIdentifier("shelf.title")
            Text(favoritesOnly ? "The ones you love the most" : "\(counted(store.items.count, singular: "tiny bestie", plural: "tiny besties")). One happy collection.")
                .font(.fun(.headline, weight: .semibold))
                .foregroundStyle(Palette.inkSoft)
        }
    }

    private var banner: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(toyCountLabel)
                    .font(.fun(.title2, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                Text("Good things come in squishy shapes.")
                    .font(.fun(.subheadline, weight: .semibold))
                    .foregroundStyle(Palette.ink.opacity(0.8))
            }
            Spacer(minLength: 0)
            if !dynamicTypeSize.isAccessibilitySize, let look = store.profile?.look {
                CritterView(look: look).frame(width: 92, height: 92)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: [Palette.sunshine, Color(hex: 0xFFC98F)], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(SparkleSprinkles(color: Palette.coral))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("shelf.counts")
    }

    private var filterChips: some View {
        FlowLayout(spacing: 8) {
            ForEach(CollectionFilter.allCases) { option in
                FunChip(title: option.label, systemImage: option.systemImage, isOn: filter == option) {
                    withAnimation(.spring(response: 0.35)) { filter = option }
                }
                .accessibilityIdentifier("filter.\(option.rawValue)")
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var content: some View {
        if needsFirstToy {
            firstToyButton
        } else if visible.isEmpty {
            emptyState(title: favoritesOnly ? "No faves yet" : "No matches", message: favoritesOnly ? "Tap the heart on a toy to make it a fave." : "Try another word or filter.")
        } else {
            LazyVGrid(columns: [GridItem(dynamicTypeSize.isAccessibilitySize ? .flexible() : .adaptive(minimum: horizontalSizeClass == .regular ? 170 : 148), spacing: 16)], spacing: 16) {
                ForEach(visible) { item in
                    card(for: item)
                }
            }
        }
    }

    private var firstToyButton: some View {
        Button(action: onAddToy) {
            VStack(spacing: 12) {
                CritterView(species: .blob, color: .bubblegum, eyes: .sparkle, mouth: .grin, accessory: .star)
                    .frame(width: 130)
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "plus")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(Palette.grape, in: Circle())
                            .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                    }
                    .accessibilityHidden(true)
                Text("Add my first toy")
                    .font(.fun(.title2, weight: .heavy))
                    .foregroundStyle(Palette.grapeDeep)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .stickerCard(border: Palette.grape)
            .contentShape(RoundedRectangle(cornerRadius: 26))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("shelf.add")
    }

    @ViewBuilder
    private func card(for item: CollectionItem) -> some View {
        let cardView = ItemCard(item: item, photo: store.image(for: item), isSelected: selection?.wrappedValue == item.id)
        if let selection {
            Button { selection.wrappedValue = item.id } label: { cardView }
                .buttonStyle(.plain)
                .accessibilityIdentifier("item.card.\(item.name)")
        } else {
            NavigationLink(value: item.id) { cardView }
                .buttonStyle(.plain)
                .accessibilityIdentifier("item.card.\(item.name)")
        }
    }

    private func emptyState(title: String, message: String) -> some View {
        VStack(spacing: 12) {
            CritterView(species: .blob, color: .bubblegum, eyes: .sparkle, mouth: .grin, accessory: .star).frame(width: 130)
            Text(title).font(.fun(.title2, weight: .heavy)).foregroundStyle(Palette.ink)
            Text(message).font(.fun(.body)).foregroundStyle(Palette.inkSoft).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .stickerCard()
    }

    private var bottomButtons: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                addButton.fixedSize(horizontal: true, vertical: false)
                shareButton.fixedSize(horizontal: true, vertical: false)
            }
            VStack(spacing: 10) {
                shareButton
                addButton
            }
        }
        .font(.fun(.headline, weight: .heavy))
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .frame(maxWidth: 900)
        .frame(maxWidth: .infinity)
        .background(LinearGradient(colors: [Palette.cream.opacity(0), Palette.cream.opacity(0.95), Palette.cream], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
    }

    private var shareButton: some View {
        Button { showingShare = true } label: {
            Label("Share my collection", systemImage: "square.and.arrow.up")
                .fixedSize(horizontal: false, vertical: true)
        }
        .buttonStyle(.chunky(Palette.grape, shadow: Palette.grapeDeep, compact: true))
        .disabled(store.items.isEmpty)
        .accessibilityIdentifier("shelf.share")
        .accessibilityHint("Makes a picture of your toys to send with a grown-up's help")
    }

    private var addButton: some View {
        Button(action: onAddToy) {
            Label("Add toy", systemImage: "plus")
        }
        .buttonStyle(.chunky(.white, shadow: Palette.lilac, foreground: Palette.grape, compact: true))
        .accessibilityIdentifier("shelf.add")
    }
}

struct ItemCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let item: CollectionItem
    var photo: UIImage?
    var isSelected = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ItemThumbnail(item: item, photo: photo)
                .frame(height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    if item.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Palette.coralDeep)
                            .padding(7)
                            .background(Circle().fill(.white))
                            .padding(8)
                    }
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.fun(.headline, weight: .heavy))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                Text(item.subtitle)
                    .font(.fun(.caption, weight: .semibold))
                    .foregroundStyle(Palette.inkSoft)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
            }
            .padding(.horizontal, 4)
        }
        .padding(10)
        .stickerCard(border: item.color.pastel, selected: isSelected)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.name), \(item.subtitle)\(item.isFavorite ? ", favorite" : "")")
    }
}

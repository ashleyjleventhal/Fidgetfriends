import SwiftUI

enum AppSection: String, Hashable, CaseIterable {
    case collection, favorites, character

    var title: String {
        switch self {
        case .collection: return "Collection"
        case .favorites: return "Favorites"
        case .character: return "My character"
        }
    }

    var systemImage: String {
        switch self {
        case .collection: return "square.grid.2x2.fill"
        case .favorites: return "heart.fill"
        case .character: return "face.smiling.inverse"
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Group {
            if store.profile == nil {
                OnboardingView()
                    .transition(.opacity)
            } else if horizontalSizeClass == .regular {
                WideMainView()
            } else {
                PhoneMainView()
            }
        }
        .tint(Palette.grape)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: store.profile == nil)
    }
}

struct PhoneMainView: View {
    @State private var section: AppSection = .collection

    var body: some View {
        TabView(selection: $section) {
            ForEach(AppSection.allCases, id: \.self) { section in
                NavigationStack {
                    switch section {
                    case .collection: ShelfScreen(favoritesOnly: false, selection: nil)
                    case .favorites: ShelfScreen(favoritesOnly: true, selection: nil)
                    case .character: CharacterScreen()
                    }
                }
                .tabItem { Label(section.title, systemImage: section.systemImage) }
                .tag(section)
            }
        }
    }
}

struct WideMainView: View {
    @EnvironmentObject private var store: AppStore
    @State private var section: AppSection = .collection
    @State private var selection: UUID?

    var body: some View {
        GeometryReader { geo in
            let sidebarWidth: CGFloat = geo.size.width > 1100 ? 270 : 230
            let showsPanel = geo.size.width - sidebarWidth >= 760
            HStack(spacing: 0) {
                WideSidebar(section: $section)
                    .frame(width: sidebarWidth)
                switch section {
                case .collection, .favorites:
                    HStack(spacing: 0) {
                        NavigationStack {
                            ShelfScreen(favoritesOnly: section == .favorites, selection: showsPanel ? $selection : nil)
                        }
                        .id(section)
                        if showsPanel {
                            DetailPanel(selection: $selection, favoritesOnly: section == .favorites)
                                .frame(width: min(420, (geo.size.width - sidebarWidth) * 0.42))
                        }
                    }
                case .character:
                    NavigationStack { CharacterScreen() }
                }
            }
        }
        .onAppear {
            if selection == nil { selection = store.items.first?.id }
        }
    }
}

private struct WideSidebar: View {
    @EnvironmentObject private var store: AppStore
    @Binding var section: AppSection

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                if let look = store.profile?.look { BuddyAvatar(look: look, size: 48) }
                Text("fidget friends")
                    .font(.fun(.title2, weight: .heavy))
                    .foregroundStyle(Palette.ink)
            }
            .padding(.bottom, 10)

            ForEach(AppSection.allCases, id: \.self) { item in
                Button {
                    section = item
                } label: {
                    Label(item.title, systemImage: item.systemImage)
                        .font(.fun(.title3))
                        .foregroundStyle(section == item ? Palette.grape : Palette.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(section == item ? .white : .clear))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("sidebar.\(item.rawValue)")
                .accessibilityAddTraits(section == item ? .isSelected : [])
            }

            Spacer()

            if let profile = store.profile {
                VStack(spacing: 6) {
                    CritterView(look: profile.look).frame(height: 120)
                    Text(profile.buddyName).font(.fun(.title2, weight: .heavy)).foregroundStyle(Palette.ink)
                    Text("Your squishy sidekick").font(.fun(.subheadline)).foregroundStyle(Palette.inkSoft)
                }
                .frame(maxWidth: .infinity)
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Palette.sunshine))
                .overlay(SparkleSprinkles(color: Palette.coral))
            }
            Label("Your collection stays on this iPad.", systemImage: "lock.fill")
                .font(.fun(.footnote))
                .foregroundStyle(Palette.grape)
        }
        .padding(20)
        .frame(maxHeight: .infinity)
        .background(LinearGradient(colors: [Palette.lilac, Color(hex: 0xE4D3FF)], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
    }
}

private struct DetailPanel: View {
    @EnvironmentObject private var store: AppStore
    @Binding var selection: UUID?
    var favoritesOnly = false

    var body: some View {
        ScrollView {
            if let item = store.item(selection), !favoritesOnly || item.isFavorite {
                ItemDetailContent(item: item) { selection = nil }
                    .padding(24)
            } else {
                VStack(spacing: 16) {
                    CritterView(species: .blob, color: .mint, eyes: .happy, mouth: .grin).frame(width: 160)
                    Text("Tap a toy to take a closer look!")
                        .font(.fun(.title3))
                        .foregroundStyle(Palette.inkSoft)
                        .multilineTextAlignment(.center)
                }
                .padding(40)
                .padding(.top, 80)
            }
        }
        .background(Palette.cream.ignoresSafeArea())
        .overlay(alignment: .leading) { Rectangle().fill(Palette.lilac).frame(width: 2).ignoresSafeArea() }
    }
}

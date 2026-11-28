import SwiftUI

struct ItemDetailScreen: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let itemID: UUID

    var body: some View {
        ScrollView {
            if let item = store.item(itemID) {
                ItemDetailContent(item: item) { dismiss() }
                    .padding(20)
                    .frame(maxWidth: 640)
                    .frame(maxWidth: .infinity)
            }
        }
        .background(WhimsyBackground())
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ItemDetailContent: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let item: CollectionItem
    var onDelete: () -> Void
    @State private var editing = false
    @State private var confirmingDelete = false
    @State private var saveFailed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ItemThumbnail(item: item, photo: store.image(for: item))
                .frame(height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).strokeBorder(.white, lineWidth: 5))
                .shadow(color: Palette.grape.opacity(0.15), radius: 14, y: 8)

            let titleLayout = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading)) : AnyLayout(HStackLayout(alignment: .top))
            titleLayout {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(.largeTitle, design: .rounded).weight(.black))
                        .foregroundStyle(Palette.ink)
                        .accessibilityIdentifier("detail.name")
                    Text(item.subtitle).font(.fun(.headline, weight: .semibold)).foregroundStyle(Palette.inkSoft)
                }
                if !dynamicTypeSize.isAccessibilitySize { Spacer() }
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        saveFailed = !store.toggleFavorite(item.id)
                    }
                } label: {
                    Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(item.isFavorite ? Palette.coralDeep : Palette.inkSoft)
                        .frame(width: 64, height: 64)
                        .background(Circle().fill(item.isFavorite ? Color(hex: 0xFFE3DE) : .white))
                        .overlay(Circle().strokeBorder(Palette.lilac, lineWidth: 2))
                        .scaleEffect(item.isFavorite ? 1.08 : 1)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.isFavorite ? "Remove from favorites" : "Add to favorites")
                .accessibilityIdentifier("detail.favorite")
            }

            if !item.tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(item.tags) { tag in
                        Text(tag.label)
                            .font(.fun(.subheadline))
                            .foregroundStyle(Palette.ink)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(tag.color))
                    }
                }
            }

            if !item.notes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Label("My private notes", systemImage: "lock.fill")
                        .font(.fun(.subheadline))
                        .foregroundStyle(Palette.grape)
                    Text(item.notes).font(.fun(.body, weight: .medium)).foregroundStyle(Palette.ink)
                        .accessibilityIdentifier("detail.notes")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .stickerCard(border: Palette.sunshine)
            }

            let actionLayout = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 12)) : AnyLayout(HStackLayout(spacing: 12))
            actionLayout {
                Button { editing = true } label: { Label("Edit", systemImage: "pencil") }
                    .buttonStyle(.chunky(Palette.mint, shadow: Palette.mintDeep, foreground: Palette.ink))
                    .accessibilityIdentifier("detail.edit")
                Button(role: .destructive) { confirmingDelete = true } label: { Label("Remove", systemImage: "trash") }
                    .buttonStyle(.chunky(.white, shadow: Palette.lilac, foreground: Palette.coralDeep))
                    .accessibilityIdentifier("detail.delete")
            }
        }
        .sheet(isPresented: $editing) { ItemEditorView(mode: .edit(item)) }
        .alert("Remove \(item.name) from your shelf?", isPresented: $confirmingDelete) {
            Button("Remove", role: .destructive) {
                if store.delete(item.id) { onDelete() } else { saveFailed = true }
            }
            Button("Keep it", role: .cancel) {}
        }
        .alert("Couldn't update your shelf", isPresented: $saveFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Free up some space, then try again.")
        }
    }
}

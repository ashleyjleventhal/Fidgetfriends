import PhotosUI
import SwiftUI

struct ItemEditorView: View {
    enum Mode {
        case add
        case edit(CollectionItem)
    }

    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let mode: Mode

    @State private var draft: CollectionItem
    @State private var photoSelection: PhotosPickerItem?
    @State private var pickedPhoto: UIImage?
    @State private var removePhoto = false
    @State private var photoState: PhotoState = .idle

    private enum PhotoState: Equatable { case idle, loading, failed(String) }

    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .add:
            _draft = State(initialValue: CollectionItem(name: "", kind: .squishy, species: .blob, color: .bubblegum))
        case .edit(let item):
            _draft = State(initialValue: item)
        }
    }

    /// Starter artwork shows only while the toy still has its original kind, look and color.
    private func syncStarterArt() {
        guard case .edit(let original) = mode else { return }
        let unchanged = draft.kind == original.kind && draft.species == original.species && draft.color == original.color
        draft.artName = unchanged ? original.artName : nil
    }

    private var isEditing: Bool { if case .edit = mode { return true } else { return false } }
    private var resolvedName: String {
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? draft.species.label : name
    }
    private var speciesChoices: [CritterSpecies] { draft.kind == .squishy ? CritterSpecies.squishyChoices : CritterSpecies.fidgetChoices }

    private var previewPhoto: UIImage? {
        if let pickedPhoto { return pickedPhoto }
        if removePhoto { return nil }
        return store.image(for: draft)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    previewCard
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(text: "It's a…")
                        HStack(spacing: 10) {
                            ForEach(ItemKind.allCases) { kind in
                                FunChip(title: kind.label, systemImage: kind == .squishy ? "cloud.fill" : "circle.grid.3x3.fill", isOn: draft.kind == kind,
                                        color: kind == .squishy ? Palette.coralDeep : Palette.skyDeep) {
                                    draft.kind = kind
                                    if !speciesChoices.contains(draft.species) { draft.species = speciesChoices[0] }
                                    syncStarterArt()
                                }
                                .accessibilityIdentifier("editor.kind.\(kind.rawValue)")
                            }
                        }
                    }
                    speciesPicker
                    colorPicker
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(text: "Name", trailing: "Optional")
                        FunTextField(placeholder: draft.species.label, text: $draft.name)
                            .accessibilityLabel("Toy name, optional")
                            .accessibilityIdentifier("editor.name")
                    }
                    tagPicker
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(text: "Private notes", trailing: "Never in shared pictures")
                        TextField("Where did you get it? What's it like?", text: $draft.notes, axis: .vertical)
                            .lineLimit(3...6)
                            .font(.fun(.body, weight: .medium))
                            .padding(16)
                            .stickerCard(radius: 20)
                            .accessibilityIdentifier("editor.notes")
                    }
                    Toggle(isOn: $draft.isFavorite) {
                        Label("One of my faves", systemImage: "heart.fill").font(.fun(.headline)).foregroundStyle(Palette.ink)
                    }
                    .tint(Palette.coral)
                    .padding(16)
                    .stickerCard()
                    .accessibilityIdentifier("editor.favorite")
                }
                .padding(20)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                Button { save() } label: {
                    Label(isEditing ? "Save changes" : "Save toy", systemImage: "checkmark")
                }
                .buttonStyle(.chunky)
                .disabled(photoState == .loading)
                .accessibilityIdentifier("editor.save")
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
                .background(Palette.cream.ignoresSafeArea(edges: .bottom))
            }
            .background(WhimsyBackground(colors: [Palette.cream, Palette.peachPastel.opacity(0.5)], density: 0.6))
            .navigationTitle(isEditing ? "Edit toy" : "Add a squishy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.font(.fun(.body)).accessibilityIdentifier("editor.cancel")
                }
            }
            .onChange(of: photoSelection) { _, newValue in
                guard let newValue else { return }
                photoState = .loading
                Task {
                    let image = try? await newValue.loadTransferable(type: Data.self).flatMap(UIImage.init(data:))
                    guard photoSelection == newValue else { return }
                    if let image {
                        pickedPhoto = image
                        removePhoto = false
                        photoState = .idle
                    } else {
                        photoState = .failed("Couldn't get that photo. Try another one.")
                    }
                }
            }
        }
    }

    private var previewCard: some View {
        HStack(spacing: 16) {
            ItemThumbnail(item: draft, photo: previewPhoto)
                .frame(width: 130, height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            VStack(alignment: .leading, spacing: 10) {
                PhotosPicker(selection: $photoSelection, matching: .images, photoLibrary: .shared()) {
                    Label(previewPhoto == nil ? "Add my photo" : "Change photo", systemImage: "photo.on.rectangle.angled")
                }
                .buttonStyle(.chunky(Palette.sunshine, shadow: Palette.sunshineDeep, foreground: Palette.ink, fullWidth: false))
                .accessibilityIdentifier("editor.photo")
                switch photoState {
                case .loading:
                    HStack(spacing: 6) {
                        ProgressView()
                        Text("Getting your photo…").font(.fun(.footnote, weight: .semibold)).foregroundStyle(Palette.inkSoft)
                    }
                    .accessibilityIdentifier("editor.photoLoading")
                case .failed(let message):
                    Text(message)
                        .font(.fun(.footnote, weight: .semibold))
                        .foregroundStyle(Palette.coralDeep)
                        .accessibilityIdentifier("editor.photoError")
                case .idle:
                    EmptyView()
                }
                if previewPhoto != nil {
                    Button("Use drawing instead") {
                        pickedPhoto = nil
                        photoSelection = nil
                        removePhoto = true
                        photoState = .idle
                    }
                    .font(.fun(.subheadline))
                    .accessibilityIdentifier("editor.removePhoto")
                } else {
                    Text("Optional: pick a photo of your own toy.")
                        .font(.fun(.footnote, weight: .semibold))
                        .foregroundStyle(Palette.inkSoft)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .stickerCard(border: draft.color.pastel)
    }

    private var speciesPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Looks like")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(speciesChoices) { species in
                        Button {
                            draft.species = species
                            syncStarterArt()
                        } label: {
                            VStack(spacing: 4) {
                                CritterView(species: species, color: draft.color, showsShadow: false).frame(width: 60, height: 60)
                                Text(species.label).font(.fun(.caption)).foregroundStyle(Palette.ink).lineLimit(1)
                            }
                            .frame(width: 90)
                            .padding(.vertical, 8)
                            .stickerCard(radius: 20, selected: draft.species == species)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(species.label)
                        .accessibilityAddTraits(draft.species == species ? .isSelected : [])
                        .accessibilityIdentifier("editor.species.\(species.rawValue)")
                    }
                }
                .padding(4)
            }
        }
    }

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Color")
            FlowLayout(spacing: 12) {
                ForEach(CritterColor.allCases) { color in
                    Button {
                        draft.color = color
                        syncStarterArt()
                    } label: {
                        Circle()
                            .fill(LinearGradient(colors: color.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 46, height: 46)
                            .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                            .overlay(Circle().strokeBorder(draft.color == color ? Palette.grape : .clear, lineWidth: 4).padding(-5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(color.label)
                    .accessibilityAddTraits(draft.color == color ? .isSelected : [])
                    .accessibilityIdentifier("editor.color.\(color.rawValue)")
                }
            }
        }
    }

    private var tagPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "It feels…")
            FlowLayout(spacing: 8) {
                ForEach(FeelTag.allCases) { tag in
                    FunChip(title: tag.label, isOn: draft.tags.contains(tag), color: Palette.grape) {
                        if let index = draft.tags.firstIndex(of: tag) { draft.tags.remove(at: index) } else { draft.tags.append(tag) }
                    }
                    .accessibilityIdentifier("editor.tag.\(tag.rawValue)")
                }
            }
        }
    }

    private func save() {
        var item = draft
        item.name = resolvedName
        if let pickedPhoto {
            guard let name = store.savePhoto(pickedPhoto) else {
                photoState = .failed("Couldn't save that photo. Try again or use the drawing.")
                return
            }
            item.photoFileName = name
        } else if removePhoto {
            item.photoFileName = nil
        }
        if isEditing { store.update(item) } else { store.add(item) }
        dismiss()
    }
}

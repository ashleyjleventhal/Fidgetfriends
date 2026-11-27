import PhotosUI
import SwiftUI

struct ItemEditorView: View {
    enum Mode {
        case add
        case edit(CollectionItem)
    }

    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .caption) private var optionWidth = 90.0
    let mode: Mode

    @State private var original: CollectionItem
    @State private var draft: CollectionItem
    @State private var photoSelection: PhotosPickerItem?
    @State private var pickedPhoto: UIImage?
    @State private var removePhoto = false
    @State private var photoState: PhotoState = .idle
    @State private var confirmingDiscard = false
    @State private var saveError: SaveError?

    private enum PhotoState: Equatable { case idle, loading, failed(String) }
    private enum SaveError: String, Identifiable {
        case photo = "Couldn't save that photo"
        case toy = "Couldn't save your toy"

        var id: String { rawValue }
    }

    init(mode: Mode) {
        self.mode = mode
        let item: CollectionItem
        switch mode {
        case .add:
            item = CollectionItem(name: "", kind: .squishy, species: .blob, color: .bubblegum)
        case .edit(let existing):
            item = existing
        }
        _original = State(initialValue: item)
        _draft = State(initialValue: item)
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-uiTestSelectedPhoto") {
            _pickedPhoto = State(initialValue: UIImage(named: "ArtPeachy"))
        }
        #endif
    }

    /// Starter artwork shows only while the toy still has its original kind, look and color.
    private func syncStarterArt() {
        guard isEditing else { return }
        let unchanged = draft.kind == original.kind && draft.species == original.species && draft.color == original.color
        draft.artName = unchanged ? original.artName : nil
    }

    private var isEditing: Bool { if case .edit = mode { return true } else { return false } }
    private var resolvedName: String {
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? draft.species.label : name
    }
    private var speciesChoices: [CritterSpecies] { draft.kind == .squishy ? CritterSpecies.squishyChoices : CritterSpecies.fidgetChoices }
    private var hasUnsavedChanges: Bool {
        draft != original || pickedPhoto != nil || photoState == .loading ||
            (removePhoto && original.photoFileName != nil)
    }

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
                        FlowLayout(spacing: 10) {
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
                        FunTextField(placeholder: draft.species.label, text: $draft.name, axis: .vertical)
                            .accessibilityLabel("Toy name, optional")
                            .accessibilityIdentifier("editor.name")
                    }
                    tagPicker
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(text: "Private notes", trailing: "Never in shared pictures")
                        TextField("Private notes", text: $draft.notes,
                                  prompt: Text("Where did you get it? What's it like?").foregroundStyle(Palette.inkSoft), axis: .vertical)
                            .foregroundStyle(Palette.ink)
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
            .navigationTitle(isEditing ? "Edit toy" : "Add a \(draft.kind.label.lowercased())")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: cancel).font(.fun(.body)).accessibilityIdentifier("editor.cancel")
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
        .background(SheetDismissObserver(isDirty: hasUnsavedChanges) { confirmingDiscard = true })
        .interactiveDismissDisabled(hasUnsavedChanges)
        .alert(isEditing ? "Throw away your changes?" : "Throw away this toy?", isPresented: $confirmingDiscard) {
            Button("Keep editing", role: .cancel) {}
            Button("Throw away", role: .destructive) { dismiss() }
        }
        .alert(item: $saveError) { error in
            Alert(title: Text(error.rawValue),
                  message: Text(error == .photo ? "Free up some space and try again, or use the drawing instead." : "Free up some space, then try again. Your changes are still here."),
                  dismissButton: .default(Text("OK")))
        }
    }

    private func cancel() {
        if hasUnsavedChanges { confirmingDiscard = true } else { dismiss() }
    }

    private var previewCard: some View {
        let layout = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16)) : AnyLayout(HStackLayout(spacing: 16))
        return layout {
            ItemThumbnail(item: draft, photo: previewPhoto)
                .frame(width: 130, height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            VStack(alignment: .leading, spacing: 10) {
                PhotosPicker(selection: $photoSelection, matching: .images, photoLibrary: .shared()) {
                    if dynamicTypeSize.isAccessibilitySize {
                        Text(previewPhoto == nil ? "Add my photo" : "Change photo")
                    } else {
                        Label(previewPhoto == nil ? "Add my photo" : "Change photo", systemImage: "photo.on.rectangle.angled")
                    }
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
                                Text(species.label).font(.fun(.caption)).foregroundStyle(Palette.ink).multilineTextAlignment(.center)
                            }
                            .frame(width: optionWidth)
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
        var newPhotoName: String?
        if let pickedPhoto {
            guard let name = store.savePhoto(pickedPhoto) else {
                saveError = .photo
                return
            }
            newPhotoName = name
            item.photoFileName = name
        } else if removePhoto {
            item.photoFileName = nil
        }
        guard isEditing ? store.update(item) : store.add(item) else {
            if let newPhotoName { store.deletePhoto(named: newPhotoName) }
            saveError = .toy
            return
        }
        dismiss()
    }
}

private struct SheetDismissObserver: UIViewControllerRepresentable {
    let isDirty: Bool
    let onAttempt: () -> Void

    func makeUIViewController(context: Context) -> Observer { Observer() }

    func updateUIViewController(_ observer: Observer, context: Context) {
        observer.isDirty = isDirty
        observer.onAttempt = onAttempt
        DispatchQueue.main.async { [weak observer] in observer?.observePresentation() }
    }

    final class Observer: UIViewController, UIAdaptivePresentationControllerDelegate {
        var isDirty = false
        var onAttempt: (() -> Void)?
        private weak var previousDelegate: UIAdaptivePresentationControllerDelegate?

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            observePresentation()
        }

        func observePresentation() {
            var candidate = parent
            while let controller = candidate {
                if let presentation = controller.presentationController,
                   presentation.presentedViewController === controller {
                    if presentation.delegate !== self {
                        previousDelegate = presentation.delegate
                        presentation.delegate = self
                    }
                    return
                }
                candidate = controller.parent
            }
        }

        func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
            !isDirty && (previousDelegate?.presentationControllerShouldDismiss?(presentationController) ?? true)
        }

        func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
            if isDirty { onAttempt?() }
            previousDelegate?.presentationControllerDidAttemptToDismiss?(presentationController)
        }

        override func responds(to selector: Selector!) -> Bool {
            super.responds(to: selector) || previousDelegate?.responds(to: selector) == true
        }

        override func forwardingTarget(for selector: Selector!) -> Any? {
            if previousDelegate?.responds(to: selector) == true { return previousDelegate }
            return super.forwardingTarget(for: selector)
        }
    }
}

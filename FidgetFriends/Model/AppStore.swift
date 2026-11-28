import SwiftUI
import UIKit

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var profile: Profile?
    @Published private(set) var items: [CollectionItem] = []
    @Published var setupDraft = SetupDraft() {
        didSet { defaults.set(try? JSONEncoder().encode(setupDraft), forKey: Self.draftKey) }
    }

    let directory: URL
    private let defaults: UserDefaults
    private var failCollectionWrites = false
    private var failPhotoWrites = false
    private static let draftKey = "onboardingDraft"
    private let photoCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 40
        return cache
    }()

    private struct Snapshot: Codable {
        var profile: Profile?
        var items: [CollectionItem]
    }

    init(directory: URL, defaults: UserDefaults = .standard) {
        self.directory = directory
        self.defaults = defaults
        if let data = try? Data(contentsOf: directory.appendingPathComponent("collection.json")),
           let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) {
            profile = snapshot.profile
            items = snapshot.items
        }
        if profile == nil, let data = defaults.data(forKey: Self.draftKey),
           let draft = try? JSONDecoder().decode(SetupDraft.self, from: data) {
            setupDraft = draft
        }
    }

    static func defaultDirectory() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FidgetFriends", isDirectory: true)
    }

    /// Launch arguments starting with `-uiTest` exist only so UI tests can start from a known state.
    static func live(arguments: [String] = ProcessInfo.processInfo.arguments) -> AppStore {
        let directory = defaultDirectory()
        if arguments.contains("-uiTestReset") {
            try? FileManager.default.removeItem(at: directory)
            UserDefaults.standard.removeObject(forKey: draftKey)
        }
        let store = AppStore(directory: directory)
        if arguments.contains("-uiTestSkipOnboarding"), store.profile == nil {
            _ = store.saveProfile(.sample)
        }
        if arguments.contains("-uiTestSeed"), store.items.isEmpty {
            _ = store.persist(profile: store.profile, items: CollectionItem.samples)
        }
        #if DEBUG
        store.failCollectionWrites = arguments.contains("-uiTestFailCollectionWrite")
        store.failPhotoWrites = arguments.contains("-uiTestFailPhotoWrite")
        #endif
        return store
    }

    var stateURL: URL { directory.appendingPathComponent("collection.json") }
    var photosDirectory: URL { directory.appendingPathComponent("Photos", isDirectory: true) }

    var squishyCount: Int { items.filter { $0.kind == .squishy }.count }
    var fidgetCount: Int { items.filter { $0.kind == .fidget }.count }
    var favoriteCount: Int { items.filter(\.isFavorite).count }

    func item(_ id: UUID?) -> CollectionItem? {
        guard let id else { return nil }
        return items.first { $0.id == id }
    }

    func saveProfile(_ profile: Profile, addSamples: Bool = false) -> Bool {
        guard persist(profile: profile, items: addSamples && items.isEmpty ? Array(CollectionItem.samples.reversed()) : items) else {
            return false
        }
        defaults.removeObject(forKey: Self.draftKey)
        return true
    }

    @discardableResult
    func add(_ item: CollectionItem) -> Bool {
        persist(profile: profile, items: [item] + items)
    }

    @discardableResult
    func update(_ item: CollectionItem) -> Bool {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return false }
        var updatedItems = items
        let oldPhoto = items[index].photoFileName
        updatedItems[index] = item
        guard persist(profile: profile, items: updatedItems) else { return false }
        if let oldPhoto, oldPhoto != item.photoFileName {
            deletePhoto(named: oldPhoto)
        }
        return true
    }

    @discardableResult
    func delete(_ id: UUID) -> Bool {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return false }
        var updatedItems = items
        let photo = updatedItems.remove(at: index).photoFileName
        guard persist(profile: profile, items: updatedItems) else { return false }
        if let photo {
            deletePhoto(named: photo)
        }
        return true
    }

    @discardableResult
    func toggleFavorite(_ id: UUID) -> Bool {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return false }
        var updatedItems = items
        updatedItems[index].isFavorite.toggle()
        return persist(profile: profile, items: updatedItems)
    }

    func savePhoto(_ image: UIImage) -> String? {
        let resized = image.resized(maxSide: 1400)
        guard let data = resized.jpegData(compressionQuality: 0.85) else { return nil }
        let name = UUID().uuidString + ".jpg"
        do {
            try FileManager.default.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
            if failPhotoWrites { throw CocoaError(.fileWriteOutOfSpace) }
            try data.write(to: photosDirectory.appendingPathComponent(name), options: [.atomic, .completeFileProtection])
            photoCache.setObject(resized, forKey: name as NSString)
            return name
        } catch {
            return nil
        }
    }

    func image(for item: CollectionItem) -> UIImage? {
        guard let name = item.photoFileName else { return nil }
        if let cached = photoCache.object(forKey: name as NSString) { return cached }
        guard let image = UIImage(contentsOfFile: photosDirectory.appendingPathComponent(name).path) else { return nil }
        photoCache.setObject(image, forKey: name as NSString)
        return image
    }

    func deletePhoto(named name: String) {
        photoCache.removeObject(forKey: name as NSString)
        try? FileManager.default.removeItem(at: photosDirectory.appendingPathComponent(name))
    }

    private func persist(profile: Profile?, items: [CollectionItem]) -> Bool {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(Snapshot(profile: profile, items: items))
            if failCollectionWrites { throw CocoaError(.fileWriteOutOfSpace) }
            try data.write(to: stateURL, options: [.atomic, .completeFileProtection])
            if self.profile != profile { self.profile = profile }
            self.items = items
            return true
        } catch {
            return false
        }
    }
}

struct SetupDraft: Codable {
    var step = 0
    var nickname = ""
    var buddyName = ""
    var look = CharacterLook()
    var addSamples = false
}

extension UIImage {
    func resized(maxSide: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxSide else { return self }
        let scale = maxSide / longest
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }
}

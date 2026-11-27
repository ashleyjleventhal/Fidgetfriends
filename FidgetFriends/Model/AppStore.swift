import SwiftUI
import UIKit

@MainActor
final class AppStore: ObservableObject {
    @Published var profile: Profile? { didSet { persist() } }
    @Published private(set) var items: [CollectionItem] = [] { didSet { persist() } }

    let directory: URL
    private var photoCache: [String: UIImage] = [:]

    private struct Snapshot: Codable {
        var profile: Profile?
        var items: [CollectionItem]
    }

    init(directory: URL) {
        self.directory = directory
        if let data = try? Data(contentsOf: directory.appendingPathComponent("collection.json")),
           let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) {
            profile = snapshot.profile
            items = snapshot.items
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
        }
        let store = AppStore(directory: directory)
        if arguments.contains("-uiTestSkipOnboarding"), store.profile == nil {
            store.profile = .sample
        }
        if arguments.contains("-uiTestSeed"), store.items.isEmpty {
            store.items = CollectionItem.samples
        }
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

    func add(_ item: CollectionItem) {
        items.insert(item, at: 0)
    }

    func update(_ item: CollectionItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        if let old = items[index].photoFileName, old != item.photoFileName {
            deletePhoto(named: old)
        }
        items[index] = item
    }

    func delete(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        if let photo = items[index].photoFileName {
            deletePhoto(named: photo)
        }
        items.remove(at: index)
    }

    func toggleFavorite(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isFavorite.toggle()
    }

    func savePhoto(_ image: UIImage) -> String? {
        let resized = image.resized(maxSide: 1400)
        guard let data = resized.jpegData(compressionQuality: 0.85) else { return nil }
        let name = UUID().uuidString + ".jpg"
        do {
            try FileManager.default.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
            try data.write(to: photosDirectory.appendingPathComponent(name), options: [.atomic, .completeFileProtection])
            photoCache[name] = resized
            return name
        } catch {
            return nil
        }
    }

    func image(for item: CollectionItem) -> UIImage? {
        guard let name = item.photoFileName else { return nil }
        if let cached = photoCache[name] { return cached }
        guard let image = UIImage(contentsOfFile: photosDirectory.appendingPathComponent(name).path) else { return nil }
        photoCache[name] = image
        return image
    }

    private func deletePhoto(named name: String) {
        photoCache[name] = nil
        try? FileManager.default.removeItem(at: photosDirectory.appendingPathComponent(name))
    }

    private func persist() {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(Snapshot(profile: profile, items: items))
            try data.write(to: stateURL, options: [.atomic, .completeFileProtection])
        } catch {
            assertionFailure("Could not save collection: \(error)")
        }
    }
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

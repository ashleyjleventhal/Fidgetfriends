import SwiftUI
import XCTest
@testable import FidgetFriends

@MainActor
final class FidgetFriendsTests: XCTestCase {
    private var directory: URL!

    override func setUp() {
        super.setUp()
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        super.tearDown()
    }

    func testFilteringByKindFavoritesAndSearch() {
        let items = CollectionItem.samples
        XCTAssertEqual(items.filtered(.all).count, items.count)
        XCTAssertTrue(items.filtered(.fidgets).allSatisfy { $0.kind == .fidget })
        XCTAssertTrue(items.filtered(.squishys).allSatisfy { $0.kind == .squishy })
        XCTAssertEqual(Set(items.filtered(.faves).map(\.name)), ["Peachy", "Pickles"])
        XCTAssertEqual(items.filtered(.all, search: "  peach ").map(\.name), ["Peachy"])
        XCTAssertEqual(items.filtered(.all, search: "clicky").map(\.name).sorted(), ["Clicky Cube", "Rainbow Pop"])
        XCTAssertTrue(items.filtered(.fidgets, search: "peachy").isEmpty)
    }

    func testProfileAndItemsPersistAcrossStores() {
        let store = AppStore(directory: directory)
        store.profile = Profile(nickname: "Kai", buddyName: "Bloop", look: CharacterLook(species: .frog, color: .mint, eyes: .happy, mouth: .grin, accessory: .headphones, cheeks: false))
        let item = CollectionItem(name: "Marshmallow", kind: .squishy, species: .bunny, color: .sky, tags: [.soft], notes: "secret")
        store.add(item)
        store.toggleFavorite(item.id)

        let reloaded = AppStore(directory: directory)
        XCTAssertEqual(reloaded.profile, store.profile)
        XCTAssertEqual(reloaded.items.count, 1)
        XCTAssertEqual(reloaded.items.first?.name, "Marshmallow")
        XCTAssertEqual(reloaded.items.first?.isFavorite, true)
        XCTAssertEqual(reloaded.profile?.look.accessory, .headphones)
    }

    func testUpdateAndDeleteRemovePhotos() throws {
        let store = AppStore(directory: directory)
        let image = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40)).image { ctx in
            UIColor.systemPink.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 40, height: 40))
        }
        let photo = try XCTUnwrap(store.savePhoto(image))
        var item = CollectionItem(name: "Toast", kind: .squishy, species: .blob, color: .tangerine, photoFileName: photo)
        store.add(item)
        XCTAssertNotNil(store.image(for: item))

        item.name = "Toasty"
        item.photoFileName = nil
        store.update(item)
        XCTAssertEqual(store.items.first?.name, "Toasty")
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.photosDirectory.appendingPathComponent(photo).path))

        store.delete(item.id)
        XCTAssertTrue(store.items.isEmpty)
    }

    func testPosterFeaturesFavoritesFirstAndCapsCount() {
        var items = (0..<20).map { CollectionItem(name: "Toy \($0)", kind: .squishy, species: .blob, color: .grape) }
        items[15].isFavorite = true
        let featured = SharePoster.featured(from: items)
        XCTAssertEqual(featured.count, SharePoster.maxItems)
        XCTAssertEqual(featured.first?.name, "Toy 15")
    }

    func testPosterRendersOnDevice() throws {
        let poster = SharePoster(items: CollectionItem.samples, totalCount: CollectionItem.samples.count, photos: [:], look: CharacterLook())
        let renderer = ImageRenderer(content: poster)
        renderer.scale = 2
        let image = try XCTUnwrap(renderer.uiImage)
        XCTAssertEqual(image.size.width * image.scale, SharePoster.size.width * 2, accuracy: 1)
    }
}

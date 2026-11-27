import XCTest

final class FidgetFriendsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
    }

    private func launch(_ arguments: [String]) {
        app.launchArguments = arguments
        app.launch()
    }

    private func screenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func element(_ id: String) -> XCUIElement {
        app.descendants(matching: .any)[id].firstMatch
    }

    private func tap(_ id: String, timeout: TimeInterval = 5) {
        let target = element(id)
        XCTAssertTrue(target.waitForExistence(timeout: timeout), "Missing \(id)")
        var swipes = 0
        while (!target.isHittable || isCoveredByShelfButtons(target)) && swipes < 6 {
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
            start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: -220)))
            swipes += 1
        }
        target.tap()
    }

    private func isCoveredByShelfButtons(_ target: XCUIElement) -> Bool {
        guard target.identifier.hasPrefix("item.card") else { return false }
        let bar = [element("shelf.share"), element("shelf.add")].filter(\.exists).map(\.frame.minY).min() ?? .infinity
        return target.frame.maxY > bar - 8
    }

    private func open(_ section: String, title: String) {
        let sidebar = element("sidebar.\(section)")
        if sidebar.exists {
            sidebar.tap()
        } else {
            app.tabBars.buttons[title].firstMatch.tap()
        }
    }

    func testOnboardingBuildsCustomCharacter() {
        launch(["-uiTestReset"])
        screenshot("01-welcome")
        tap("onboarding.start")
        tap("onboarding.nickname")
        app.typeText("Juniper")
        tap("onboarding.next")
        tap("builder.species.cat")
        tap("builder.color.mint")
        tap("builder.eyes.happy")
        tap("builder.accessory.headphones")
        screenshot("02-character-builder")
        tap("onboarding.finish")
        XCTAssertTrue(element("shelf.title").waitForExistence(timeout: 5))
        XCTAssertTrue(element("item.card.Peachy").waitForExistence(timeout: 3))
        screenshot("03-happy-shelf")

        open("character", title: "My character")
        XCTAssertTrue(element("character.title").waitForExistence(timeout: 3))
        XCTAssertTrue(element("builder.species.cat").isSelected)
        XCTAssertTrue(element("builder.accessory.headphones").isSelected)
        screenshot("04-my-character")
    }

    func testAddedToyPersistsAfterRelaunch() {
        launch(["-uiTestReset", "-uiTestSkipOnboarding"])
        tap("shelf.add")
        tap("editor.name")
        app.typeText("Marshmallow")
        tap("editor.species.bunny")
        tap("editor.color.sky")
        tap("editor.tag.soft")
        screenshot("05-add-toy")
        tap("editor.save")
        XCTAssertTrue(element("item.card.Marshmallow").waitForExistence(timeout: 3))

        app.terminate()
        launch(["-uiTestSkipOnboarding"])
        XCTAssertTrue(element("item.card.Marshmallow").waitForExistence(timeout: 5))
        screenshot("06-after-relaunch")
    }

    func testFavoriteAndFilterNavigation() {
        launch(["-uiTestReset", "-uiTestSkipOnboarding", "-uiTestSeed"])
        tap("filter.fidgets")
        XCTAssertTrue(element("item.card.Rainbow Pop").waitForExistence(timeout: 3))
        XCTAssertFalse(element("item.card.Peachy").exists)
        screenshot("07-fidgets-filter")
        tap("filter.all")

        tap("item.card.Mochi")
        tap("detail.favorite")
        XCTAssertEqual(element("detail.favorite").label, "Remove from favorites")

        open("favorites", title: "Favorites")
        XCTAssertTrue(element("item.card.Mochi").waitForExistence(timeout: 3))
        XCTAssertTrue(element("item.card.Peachy").exists)
        XCTAssertFalse(element("item.card.Sunny").exists)
        screenshot("08-favorites")
    }

    func testIPadLayoutChangesKeepFavoritesAndAddToyDraft() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad)
        let device = XCUIDevice.shared
        device.orientation = .landscapeLeft
        defer { device.orientation = .portrait }
        launch(["-uiTestReset", "-uiTestSkipOnboarding", "-uiTestSeed", "-uiTestLayoutByOrientation"])

        tap("sidebar.favorites")
        device.orientation = .portrait
        let favoritesTab = app.tabBars.buttons["Favorites"].firstMatch
        XCTAssertTrue(favoritesTab.waitForExistence(timeout: 5))
        XCTAssertTrue(favoritesTab.isSelected)
        XCTAssertEqual(element("shelf.title").label, "My favorites")
        screenshot("12-favorites-compact")

        tap("shelf.add")
        tap("editor.kind.fidget")
        device.orientation = .landscapeLeft
        let fidget = element("editor.kind.fidget")
        XCTAssertTrue(fidget.waitForExistence(timeout: 5))
        XCTAssertTrue(fidget.isSelected)
        screenshot("13-draft-after-layout-change")
        tap("editor.cancel")

        let favoritesSidebar = element("sidebar.favorites")
        XCTAssertTrue(favoritesSidebar.waitForExistence(timeout: 5))
        XCTAssertTrue(favoritesSidebar.isSelected)
        tap("shelf.add")
        let squishy = element("editor.kind.squishy")
        XCTAssertTrue(squishy.waitForExistence(timeout: 5))
        XCTAssertTrue(squishy.isSelected)
        tap("editor.cancel")
    }

    func testShareRequiresGrownUpThenOpensShareSheet() {
        launch(["-uiTestReset", "-uiTestSkipOnboarding", "-uiTestSeed"])
        tap("shelf.share")
        XCTAssertTrue(element("share.poster").waitForExistence(timeout: 5))
        screenshot("09-share-preview")
        XCTAssertFalse(element("share.open").exists)
        tap("share.continue")

        let question = element("gate.question")
        XCTAssertTrue(question.waitForExistence(timeout: 3))
        screenshot("10-grown-up-gate")
        let answer = Self.answer(to: question.label)
        XCTAssertNotNil(answer, "Could not read \(question.label)")
        for digit in String(answer ?? 0) { tap("gate.key.\(digit)") }
        tap("gate.submit")

        tap("share.open")
        let sheet = app.otherElements["ActivityListView"].firstMatch
        let copy = app.descendants(matching: .any).matching(NSPredicate(format: "label IN %@", ["Copy", "Save Image", "Messages"])).firstMatch
        XCTAssertTrue(sheet.waitForExistence(timeout: 8) || copy.waitForExistence(timeout: 2), "System share sheet did not appear")
        let imageAction = app.descendants(matching: .any).matching(NSPredicate(format: "label IN %@", ["Save Image", "Save to Photos"])).firstMatch
        XCTAssertTrue(imageAction.waitForExistence(timeout: 10), "System share sheet did not offer to save the poster")
        screenshot("11-system-share-sheet")
    }

    static func answer(to question: String) -> Int? {
        let words = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]
        let numbers = question.lowercased()
            .components(separatedBy: CharacterSet.letters.inverted)
            .compactMap { words.firstIndex(of: $0) }
        guard numbers.count == 2 else { return nil }
        return numbers[0] * numbers[1]
    }
}

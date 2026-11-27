import UIKit
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

    func testShareRequiresGrownUpThenOpensShareSheet() {
        launch(["-uiTestReset", "-uiTestSkipOnboarding", "-uiTestSeed"])
        tap("shelf.share")
        XCTAssertTrue(element("share.poster").waitForExistence(timeout: 5))
        screenshot("09-share-preview")
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
        screenshot("11-system-share-sheet")
    }

    func testAllFiltersAreVisibleAndFavoritesCanBeSelected() {
        launch(["-uiTestReset", "-uiTestSkipOnboarding", "-uiTestSeed"])
        XCTAssertTrue(element("filter.all").waitForExistence(timeout: 5))
        for filter in ["all", "squishys", "fidgets", "faves"] {
            let chip = element("filter.\(filter)")
            XCTAssertTrue(chip.isHittable, "\(filter) should not require horizontal scrolling")
            XCTAssertTrue(app.frame.contains(chip.frame), "\(filter) should be fully visible")
        }
        screenshot("after-filters")
        tap("filter.faves")
        XCTAssertTrue(element("item.card.Peachy").waitForExistence(timeout: 3))
        XCTAssertFalse(element("item.card.Sunny").exists)
    }

    func testFiltersFitAtLargestDynamicTypeSize() {
        launch(["-uiTestReset", "-uiTestSkipOnboarding", "-uiTestSeed",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        let title = element("shelf.title")
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(title.frame.height, 60, "Expected accessibility-sized text")
        XCTAssertGreaterThanOrEqual(title.frame.minX, app.frame.minX)

        let faves = element("filter.faves")
        XCTAssertTrue(faves.exists)
        let share = element("shelf.share")
        for _ in 0..<4 {
            if faves.isHittable && faves.frame.maxY < share.frame.minY { break }
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45))
            start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: -130)))
        }
        for filter in ["all", "squishys", "fidgets", "faves"] {
            let chip = element("filter.\(filter)")
            XCTAssertGreaterThanOrEqual(chip.frame.minX, app.frame.minX)
            XCTAssertLessThanOrEqual(chip.frame.maxX, app.frame.maxX)
        }
        XCTAssertTrue(faves.isHittable)
        XCTAssertLessThan(faves.frame.maxY, share.frame.minY)
        screenshot("after-filters-largest-type")
        faves.tap()
        XCTAssertTrue(faves.isSelected)
    }

    func testUnsavedAddDraftSurvivesDismissAttempt() {
        launch(["-uiTestReset", "-uiTestSkipOnboarding"])
        tap("shelf.add")
        tap("editor.name")
        app.typeText("Unfinished yo-yo")

        if UIDevice.current.userInterfaceIdiom == .phone {
            let sheetTop = app.navigationBars["Add a squishy"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            sheetTop.press(forDuration: 0.05, thenDragTo: sheetTop.withOffset(CGVector(dx: 0, dy: 500)))
        } else {
            tap("editor.cancel")
        }
        let alert = app.alerts["Throw away this toy?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        screenshot("after-draft-dismiss-attempt")
        alert.buttons["Keep editing"].tap()
        XCTAssertEqual(element("editor.name").value as? String, "Unfinished yo-yo")

        tap("editor.cancel")
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        alert.buttons["Throw away"].tap()
        XCTAssertTrue(element("shelf.add").waitForExistence(timeout: 3))
        XCTAssertFalse(element("item.card.Unfinished yo-yo").exists)
        tap("shelf.add")
        tap("editor.cancel")
        XCTAssertTrue(element("shelf.add").waitForExistence(timeout: 3))
        XCTAssertFalse(alert.exists)
    }

    func testUnsavedEditCanBeKeptOrDiscarded() {
        launch(["-uiTestReset", "-uiTestSkipOnboarding", "-uiTestSeed"])
        tap("item.card.Peachy")
        tap("detail.edit")
        tap("editor.kind.fidget")
        tap("editor.cancel")
        let alert = app.alerts["Throw away your changes?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        alert.buttons["Keep editing"].tap()
        XCTAssertTrue(element("editor.kind.fidget").isSelected)
        tap("editor.cancel")
        alert.buttons["Throw away"].tap()
        tap("detail.edit")
        XCTAssertTrue(element("editor.kind.squishy").isSelected)
    }

    func testAddTitleAndOtherSubtypeFollowSelectedKind() {
        launch(["-uiTestReset", "-uiTestSkipOnboarding"])
        tap("shelf.add")
        XCTAssertTrue(app.navigationBars["Add a squishy"].exists)
        tap("editor.species.otherSquishy")
        XCTAssertTrue(element("editor.species.otherSquishy").isSelected)
        screenshot("after-squishy-other")

        tap("editor.kind.fidget")
        XCTAssertTrue(app.navigationBars["Add a fidget"].exists)
        tap("editor.species.otherFidget")
        XCTAssertTrue(element("editor.species.otherFidget").isSelected)
        screenshot("after-fidget-title-and-other")
        tap("editor.name")
        app.typeText("Yo-yo")
        tap("editor.save")

        app.terminate()
        launch(["-uiTestSkipOnboarding"])
        tap("item.card.Yo-yo")
        XCTAssertTrue(app.staticTexts["Fidget · Other"].exists)
    }

    func testRemoveConfirmationLetsMeKeepOrRemoveToy() {
        launch(["-uiTestReset", "-uiTestSkipOnboarding", "-uiTestSeed"])
        tap("item.card.Peachy")
        tap("detail.delete")
        let alert = app.alerts["Remove Peachy from your shelf?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        let keep = alert.buttons["Keep it"]
        XCTAssertTrue(keep.isHittable)
        screenshot("after-delete")
        keep.tap()
        XCTAssertEqual(element("detail.name").label, "Peachy")

        tap("detail.delete")
        alert.buttons["Remove"].tap()
        XCTAssertTrue(element("shelf.title").waitForExistence(timeout: 3))
        XCTAssertFalse(element("item.card.Peachy").exists)
    }

    func testGrownUpCheckControlsStayPutAfterWrongAnswer() {
        launch(["-uiTestReset", "-uiTestSkipOnboarding", "-uiTestSeed"])
        tap("shelf.share")
        tap("share.continue")
        tap("gate.key.0")
        let controls = ["gate.key.1", "gate.key.0", "gate.cancel", "gate.submit"].map(element)
        let check = element("gate.submit")
        if !check.isHittable { app.swipeUp() }
        XCTAssertTrue(check.isHittable)
        let frames = controls.map(\.frame)
        screenshot("after-gate-prompt")
        check.tap()
        XCTAssertTrue(app.staticTexts["Not quite — try a new one."].waitForExistence(timeout: 3))
        XCTAssertEqual(controls.map(\.frame), frames)
        screenshot("after-gate-error")
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

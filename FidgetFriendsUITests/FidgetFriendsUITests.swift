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
        while (!target.isHittable || isCoveredByBottomActions(target)) && swipes < 6 {
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
            start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: -220)))
            swipes += 1
        }
        target.tap()
    }

    private func isCoveredByBottomActions(_ target: XCUIElement) -> Bool {
        let actions: [String]
        switch target.identifier {
        case let id where id.hasPrefix("item.card"):
            actions = ["shelf.share", "shelf.add"]
        case let id where id.hasPrefix("editor.") && id != "editor.save":
            actions = ["editor.save"]
        default:
            return false
        }
        let bar = actions.map { element($0) }.filter(\.exists).map(\.frame.minY).min() ?? .infinity
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
        tap("onboarding.samples")
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
        XCTAssertTrue(app.staticTexts["Hi Juniper! Change your buddy any time."].exists)
        XCTAssertTrue(element("builder.species.cat").isSelected)
        XCTAssertTrue(element("builder.accessory.headphones").isSelected)
        screenshot("04-my-character")
    }

    func testFirstRunAddsAPicturedToyWithoutTyping() {
        launch(["-uiTestReset"])
        tap("onboarding.start")
        let next = element("onboarding.next")
        XCTAssertTrue(next.waitForExistence(timeout: 3))
        XCTAssertTrue(next.isEnabled)
        next.tap()

        let finish = element("onboarding.finish")
        XCTAssertTrue(finish.waitForExistence(timeout: 3))
        XCTAssertTrue(finish.isHittable, "Finishing should not require scrolling through customization")
        tap("builder.species.cat")
        tap("builder.color.mint")
        XCTAssertTrue(element("builder.color.mint").isSelected)
        XCTAssertTrue(finish.isHittable)
        finish.tap()

        let add = app.buttons["shelf.add"].firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 3))
        XCTAssertTrue(add.isHittable)
        XCTAssertEqual(add.label, "Add my first toy")
        XCTAssertFalse(element("shelf.share").exists)
        XCTAssertFalse(element("item.card.Peachy").exists)
        XCTAssertTrue(element("shelf.counts").label.contains("0 squishies & 0 fidgets"))
        screenshot("first-run-empty-shelf")
        add.tap()

        let save = element("editor.save")
        XCTAssertTrue(save.waitForExistence(timeout: 3))
        XCTAssertTrue(save.isEnabled, "A toy name should not be required")
        tap("editor.species.bunny")
        tap("editor.color.sky")
        XCTAssertTrue(element("editor.color.sky").isSelected)
        XCTAssertTrue(save.isHittable)
        save.tap()

        let bunny = element("item.card.Bunny")
        XCTAssertTrue(bunny.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["1 tiny bestie. One happy collection."].exists)
        XCTAssertTrue(element("shelf.counts").label.contains("1 squishy & 0 fidgets"))
        screenshot("first-run-bunny-on-shelf")
        app.terminate()
        launch([])
        XCTAssertTrue(bunny.waitForExistence(timeout: 5))
        tap("shelf.share")
        let poster = element("share.poster")
        XCTAssertTrue(poster.waitForExistence(timeout: 5))
        XCTAssertEqual(poster.label, "Collection picture with 1 toy")
        tap("share.close")

        open("character", title: "My character")
        XCTAssertTrue(app.staticTexts["Hi friend! Change your buddy any time."].waitForExistence(timeout: 3))
        XCTAssertTrue(element("builder.species.cat").isSelected)
        XCTAssertTrue(element("builder.color.mint").isSelected)
    }

    func testAddedToyPersistsAfterRelaunch() {
        launch(["-uiTestReset", "-uiTestSkipOnboarding"])
        tap("shelf.add")
        tap("editor.species.bunny")
        tap("editor.color.sky")
        tap("editor.tag.soft")
        tap("editor.name")
        app.textFields["editor.name"].typeText("Marshmallow")
        screenshot("05-add-toy")
        tap("editor.save")
        XCTAssertTrue(element("item.card.Marshmallow").waitForExistence(timeout: 3))

        app.terminate()
        launch(["-uiTestSkipOnboarding"])
        XCTAssertTrue(element("item.card.Marshmallow").waitForExistence(timeout: 5))
        screenshot("06-after-relaunch")
    }

    func testClearingCustomBuddyNameRestoresDefault() {
        launch(["-uiTestReset"])
        tap("onboarding.start")
        tap("onboarding.next")
        tap("builder.buddyName")
        app.typeText("Bubbles")
        tap("onboarding.finish")
        XCTAssertTrue(element("shelf.title").waitForExistence(timeout: 5))
        app.terminate()
        launch([])
        open("character", title: "My character")

        tap("builder.buddyName")
        let field = app.textFields["builder.buddyName"]
        XCTAssertEqual(field.value as? String, "Bubbles")
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        app.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "Bubbles".count))
        tap("character.save")
        app.terminate()
        launch([])
        open("character", title: "My character")
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        XCTAssertEqual(field.value as? String, "Pip")
    }

    func testFavoriteAndFilterNavigation() {
        launch(["-uiTestReset", "-uiTestSkipOnboarding", "-uiTestSeed"])
        XCTAssertTrue(element("shelf.counts").waitForExistence(timeout: 3))
        XCTAssertTrue(element("shelf.counts").label.contains("5 squishies & 2 fidgets"))
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
        let discard = app.alerts["Throw away this toy?"]
        XCTAssertTrue(discard.waitForExistence(timeout: 5))
        discard.buttons["Throw away"].tap()
        XCTAssertTrue(fidget.waitForNonExistence(timeout: 5))

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

        openGate()
        screenshot("10-grown-up-gate")
        let firstKey = element("gate.key.1")
        let originalPosition = firstKey.frame.minY
        tap("gate.key.0")
        tap("gate.submit")
        XCTAssertTrue(app.staticTexts["Not quite — try a new one."].waitForExistence(timeout: 3))
        XCTAssertEqual(firstKey.frame.minY, originalPosition, accuracy: 1)
        XCTAssertFalse(element("gate.submit").isEnabled)
        XCTAssertFalse(shareSheet.exists)

        tap("gate.cancel")
        XCTAssertTrue(element("share.continue").waitForExistence(timeout: 3))
        XCTAssertFalse(shareSheet.exists)

        openGate()
        tryAnsweringGate()
        XCTAssertTrue(shareSheet.waitForExistence(timeout: 8), "System share sheet did not appear")
        let imageAction = app.descendants(matching: .any).matching(NSPredicate(format: "label IN %@", ["Save Image", "Save to Photos"])).firstMatch
        XCTAssertTrue(imageAction.waitForExistence(timeout: 10), "System share sheet did not offer to save the poster")
        screenshot("11-system-share-sheet")

        let copy = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Copy")).firstMatch
        XCTAssertTrue(copy.waitForExistence(timeout: 5) && copy.isHittable)
        copy.tap()
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: shareSheet)
        XCTAssertEqual(XCTWaiter.wait(for: [gone], timeout: 5), .completed)
        XCTAssertEqual(app.state, .runningForeground)
        openGate()
    }

    func testBackgroundingClearsGateAndDismissesShareSheet() {
        launch(["-uiTestReset", "-uiTestSkipOnboarding", "-uiTestSeed"])
        tap("shelf.share")
        openGate()
        tap("gate.key.1")
        goHomeAndReturn()

        openGate()
        XCTAssertFalse(element("gate.submit").isEnabled)
        tryAnsweringGate()
        XCTAssertTrue(shareSheet.waitForExistence(timeout: 8))
        goHomeAndReturn()
        openGate()
    }

    private func openGate() {
        XCTAssertTrue(element("share.continue").waitForExistence(timeout: 5))
        XCTAssertFalse(shareSheet.exists)
        tap("share.continue")
        XCTAssertTrue(element("gate.question").waitForExistence(timeout: 3))
    }

    private func tryAnsweringGate() {
        let question = element("gate.question").label
        guard let answer = Self.answer(to: question) else {
            XCTFail("Could not read \(question)")
            return
        }
        for digit in String(answer) { tap("gate.key.\(digit)") }
        tap("gate.submit")
    }

    private var shareSheet: XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label IN %@", ["Copy", "Save Image"])).firstMatch
    }

    private func goHomeAndReturn() {
        XCUIDevice.shared.press(.home)
        XCTAssertTrue(app.wait(for: .runningBackground, timeout: 5) || app.state == .runningBackgroundSuspended)
        app.activate()
    }

    func testShareAndGrownUpActionsFitWithoutScrollingInPortrait() {
        XCUIDevice.shared.orientation = .portrait
        launch(["-uiTestReset", "-uiTestSkipOnboarding", "-uiTestSeed"])
        tap("shelf.share")
        XCTAssertTrue(element("share.poster").waitForExistence(timeout: 5))
        let ask = element("share.continue")
        let viewport = element("share.viewport")
        XCTAssertTrue(ask.isHittable)
        XCTAssertTrue(viewport.frame.contains(ask.frame), "Ask a grown-up should fit inside the sheet")
        ask.tap()

        XCTAssertTrue(element("gate.question").waitForExistence(timeout: 5))
        let zero = element("gate.key.0")
        XCTAssertTrue(zero.isHittable, "The last row of the keypad should be reachable without scrolling")
        zero.tap()
        for id in ["gate.cancel", "gate.submit"] {
            let button = element(id)
            XCTAssertTrue(button.isHittable, "\(id) should be hittable without scrolling")
            XCTAssertTrue(app.frame.contains(button.frame), "\(id) should fit inside the window")
            if UIDevice.current.userInterfaceIdiom == .pad {
                XCTAssertTrue(viewport.frame.contains(button.frame), "\(id) should fit inside the sheet")
            }
        }
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

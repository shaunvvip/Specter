import XCTest

final class SmokeTests: XCTestCase {
    func test_launchAndSeeSidebar() {
        let app = XCUIApplication()
        app.launch()
        // The sidebar list element appears once the NavigationSplitView is up.
        XCTAssertTrue(
            app.outlines.firstMatch.waitForExistence(timeout: 5) ||
            app.collectionViews.firstMatch.waitForExistence(timeout: 1),
            "Sidebar list should be visible on launch"
        )
        // At least one category label should be rendered.
        let appearanceLabel = app.staticTexts["外观"]
        XCTAssertTrue(appearanceLabel.waitForExistence(timeout: 2), "外观 category label should be visible")
    }
}

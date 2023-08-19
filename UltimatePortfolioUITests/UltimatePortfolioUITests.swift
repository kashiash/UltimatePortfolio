//
//  UltimatePortfolioUITests.swift
//  UltimatePortfolioUITests
//
//  Created by Jacek Kosinski U on 19/08/2023.
//

import XCTest

extension XCUIElement {
    func clear() {
        guard let stringValue = self.value as? String else {
            XCTFail("Failed to clear text in XCUIElement")
            return
        }

        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
    }
}

final class UltimatePortfolioUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {

        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["enable-testing"]
        app.launch()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.

        XCTAssertTrue(app.navigationBars.element.exists, "There should be a navigation bar when the app launches.")
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testNoIssuesAtStart() {
        XCTAssertEqual(app.cells.count, 0, "There should be 0 list rows initially.")
    }

    func testAppHasBasicButtonsOnLaunch() throws {
        XCTAssertTrue(app.navigationBars.buttons["Filters"].exists, "There should be a Filters button on launch.")
        XCTAssertTrue(app.navigationBars.buttons["Filter"].exists, "There should be a Filters button on launch.")
        XCTAssertTrue(app.navigationBars.buttons["New Issue"].exists, "There should be a Filters button on launch.")
    }

}

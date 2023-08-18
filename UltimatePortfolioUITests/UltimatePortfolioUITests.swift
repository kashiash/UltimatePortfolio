//
//  UltimatePortfolioUITests.swift
//  UltimatePortfolioUITests
//
//  Created by Jacek Kosinski U on 18/08/2023.
//

import XCTest

final class UltimatePortfolioUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        
        continueAfterFailure = false

        let app = XCUIApplication()
        app.launchArguments = ["enable-testing"]
        app.launch()

    }

    func testAppStartWithBar() throws {
        // UI tests must launch the application that they test.


        XCTAssertTrue(app.navigationBars.element.exists, "There should be navigation bar when the app launches")
    }

}

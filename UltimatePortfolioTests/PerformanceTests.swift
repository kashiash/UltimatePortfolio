//
//  PerformanceTests.swift
//  UltimatePortfolioTests
//
//  Created by Jacek Kosinski U on 05/08/2023.
//

import XCTest
@testable import UltimatePortfolio

class PerformanceTests: BaseTestCase {

    func testAwardCalculationPerformanceNormal() {

            dataController.createSampleData()

        let awards = Award.allAwards
        XCTAssertEqual(awards.count, 20, "Number of award should be constant")
        measure {
            _ = awards.filter(dataController.hasEarned)
        }
    }

    func testAwardCalculationPerformanceLarge() {
        for _ in  1...100 {
            dataController.createSampleData()
        }
        let awards = Array(repeating: Award.allAwards, count: 25).joined()
        XCTAssertEqual(awards.count, 500, "Number of award should be constant")
        measure {
            _ = awards.filter(dataController.hasEarned)
        }
    }

}

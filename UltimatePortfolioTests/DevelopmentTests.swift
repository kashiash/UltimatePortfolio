//
//  DevelopmentTests.swift
//  UltimatePortfolioTests
//
//  Created by Jacek Kosinski U on 30/07/2023.
//
import CoreData
import XCTest
@testable import UltimatePortfolio

final class DevelopmentTests: BaseTestCase {

    func testSampleDataCreationWorks() {
        dataController.createSampleData()
        XCTAssertEqual(dataController.count(for: Tag.fetchRequest()), 5, "There should be 5 sample tags")
        XCTAssertEqual(dataController.count(for: Issue.fetchRequest()), 50, "There should be 50 sample issues")
    }

    func testDeleteAllClearsEverything() {
        dataController.createSampleData()
        dataController.deleteAll()
        XCTAssertEqual(dataController.count(for: Tag.fetchRequest()), 0, "There should be no tags after delete all")
        XCTAssertEqual(dataController.count(for: Issue.fetchRequest()), 0, "There should be no issues after delete all")
    }

    func testNewTagHasNoIssues() {
        let tag = Tag.example

        XCTAssertEqual(tag.issues?.count, 0, "The example tag should have 0 issues")
    }

    func testNewIssueHasHighPriority() {
        let issue = Issue.example

        XCTAssertEqual(issue.priority, 2, "New issue should have high priority")
    }

}

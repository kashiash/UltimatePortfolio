//
//  TagTests.swift
//  UltimatePortfolioTests
//
//  Created by Jacek Kosinski U on 16/07/2023.
//
import CoreData
import XCTest
@testable import UltimatePortfolio

final class TagTests: BaseTestCase {

    func testCreatingTagsAndIssues() {
        let targetCount = 10
        for _ in 0 ..< targetCount {
            let tag = Tag(context: managedObjectContext)
            for _ in 0 ..< targetCount {
                let issue = Issue(context: managedObjectContext)
                tag.addToIssues(issue)
            }
        }
        XCTAssertEqual(dataController.count(for: Tag.fetchRequest()), targetCount, "there Expected \(targetCount) tags")
        XCTAssertEqual(dataController.count(for: Issue.fetchRequest()), targetCount * targetCount,
                       "Expected \(targetCount * targetCount ) issues")

    }
    func testDeletingTagDoesNotDeleteIssues() throws {
        dataController.createSampleData()
        let request = NSFetchRequest<Tag>(entityName: "Tag")
        let tags = try managedObjectContext.fetch(request)

        dataController.delete(tags[0])
        XCTAssertEqual(dataController.count(for: Tag.fetchRequest()), 4,
                       "There should be 4 tags after deleting 1 from samle data")
        XCTAssertEqual(dataController.count(for: Issue.fetchRequest()), 50,
                       "There should be 50 issues after deleting 1 tag from samle data")
    }
}

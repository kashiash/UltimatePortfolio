//
//  UltimatePortfolioTests.swift
//  UltimatePortfolioTests
//
//  Created by Jacek Kosinski U on 11/06/2023.
//

import XCTest
import CoreData
@testable import UltimatePortfolio

final class BaseTestCase: XCTestCase {

    var dataController: DataController!
    var managedObjectContext: NSManagedObjectContext!

    override func setUpWithError() throws {
        dataController = DataController(inMemory: true)
        managedObjectContext = dataController.container.viewContext
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }



}

//
//  UltimatePortfolioTests.swift
//  UltimatePortfolioTests
//
//  Created by Jacek Kosinski U on 11/06/2023.
//

import XCTest
import CoreData
@testable import UltimatePortfolio

class BaseTestCase: XCTestCase {

    var dataController: DataController!
    var managedObjectContext: NSManagedObjectContext!

    override func setUpWithError() throws {
        dataController = DataController(inMemory: true)
        managedObjectContext = dataController.container.viewContext
    }

}

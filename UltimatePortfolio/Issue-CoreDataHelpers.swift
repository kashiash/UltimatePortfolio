//
//  Issue-CoreDataHelpers.swift
//  UltimatePortfolio
//
//  Created by Jacek Kosiński G on 26/02/2023.
//

import Foundation
extension Issue {
    var issueTitle: String {
        get { title ?? "" }
        set { title = newValue }
    }

    var issueContent: String {
        get { content ?? "" }
        set { content = newValue }
    }

    var issueTaskAddress: String {
        get { taskAddress ?? "" }
        set { taskAddress = newValue }
    }
    
    var issueCreationDate: Date {
        creationDate ?? .now
    }

    var issueModificationDate: Date {
        modificationDate ?? .now
    }
    
    var issueDueDate: Date {
        dueDate ?? .now
    }
    var issueStartDate: Date {
        startDate ?? .now
    }

    var issueTags: [Tag] {
        let result = tags?.allObjects as? [Tag] ?? []
        return result.sorted()
    }
    
    var issueStatus: String {
        if completed {
            return "Closed"
        } else {
            return "Open"
        }
    }
    var issueFormattedCreationDate: String {
        issueCreationDate.formatted(date: .numeric, time: .omitted)
    }
    
    var issueFormattedDueDate : String{
        issueDueDate.formatted(date: .numeric, time: .standard)
    }
    
    var issueTagsList: String {
        guard let tags else { return "No tags" }

        if tags.count == 0 {
            return "No tags"
        } else {
            return issueTags.map(\.tagName).formatted()
        }
    }

    static var example: Issue {
        let controller = DataController(inMemory: true)
        let viewContext = controller.container.viewContext

        let issue = Issue(context: viewContext)
        issue.title = "Example Issue"
        issue.content = "This is an example issue."
        issue.issueTaskAddress = "Plac Defilad 1, Warszawa"
        issue.priority = 2
        issue.creationDate = .now
        issue.startDate = .now
        issue.dueDate = .now
        return issue
    }
}

extension Issue: Comparable {
    public static func <(lhs: Issue, rhs: Issue) -> Bool {
        let left = lhs.issueTitle.localizedLowercase
        let right = rhs.issueTitle.localizedLowercase

        if left == right {
            return lhs.issueCreationDate < rhs.issueCreationDate
        } else {
            return left < right
        }
    }
}

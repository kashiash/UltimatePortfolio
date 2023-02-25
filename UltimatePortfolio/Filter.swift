//
//  Filter.swift
//  UltimatePortfolio
//
//  Created by Jacek Kosiński G on 25/02/2023.
//

import Foundation


struct Filter: Identifiable,Hashable {
    var id: UUID
    var name: String
    var icon: String
    var minModificationdate = Date.distantPast
    var tag: Tag?
    
    static var all = Filter(id: UUID(), name: "All issues", icon: "tray")
    static var recent = Filter(id: UUID(), name: "Recent issues", icon: "clock", minModificationdate: .now.addingTimeInterval(86400 * -7))
    
    func hash (into hasher: inout Hasher){
        hasher.combine(id)
    }
    static func == (lhs: Filter, rhs: Filter) -> Bool {
        lhs.id == rhs.id
    }
}
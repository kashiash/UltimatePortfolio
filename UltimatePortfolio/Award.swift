//
//  Award.swift
//  UltimatePortfolio
//
//  Created by Jacek Kosiński G on 09/04/2023.
//

import Foundation


struct Award: Decodable, Identifiable {
    var id: String { name }
    var name: String
    var description: String
    var color: String
    var criterion: String
    var value: Int
    var image: String
    
    static let allAwards = Bundle.main.decode("Awards.json", as: [Award].self)
    static let example = allAwards[0]
}

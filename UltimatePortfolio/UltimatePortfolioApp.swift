//
//  UltimatePortfolioApp.swift
//  UltimatePortfolio
//
//  Created by Jacek Kosiński G on 25/02/2023.
//

import SwiftUI

@main
struct UltimatePortfolioApp: App {
    @StateObject var dataController = DataController()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(dataController)
        }
    }
}

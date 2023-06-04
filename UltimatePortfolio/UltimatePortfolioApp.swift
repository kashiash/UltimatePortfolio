//  UltimatePortfolioApp.swift
//  UltimatePortfolio
//
//  Created by Jacek Kosiński G on 25/02/2023.
//

import SwiftUI

@main
struct UltimatePortfolioApp: App {
    @StateObject var dataController = DataController()
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                SidebarView()
            } content: {
                ContentView()
            } detail: {
                DetailView()
            }
            .environment(\.managedObjectContext, dataController.container.viewContext)
            .environmentObject(dataController)
            .onChange(of: scenePhase) { phase in
                if phase != .active {
                    dataController.save()
                    print("Exit Save")
                }
            }
        }
    }
}

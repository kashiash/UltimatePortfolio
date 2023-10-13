//
//  ContentViewModel.swift
//  UltimatePortfolio
//
//  Created by Jacek Kosinski U on 13/10/2023.
//

import Foundation

extension ContentView {
    
    class ViewModel : ObservableObject {
        var dataController: DataController

        init(dataController: DataController) {
            self.dataController = dataController
        }
        func delete(_ offsets: IndexSet) {
            let issues = dataController.issuesForSelectedFilter()

            for offset in offsets {
                let item = issues[offset]
                dataController.delete(item)
            }
        }

    }
}

//
//  ContentView.swift
//  UltimatePortfolio
//
//  Created by Jacek Kosiński G on 25/02/2023.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel: ViewModel

    var body: some View {
        List(selection: $viewModel.dataController.selectedIssue) {
            ForEach(viewModel.dataController.issuesForSelectedFilter()) { issue in
                IssueRow(issue: issue)
            }
            .onDelete(perform: viewModel.delete)
        }
        .navigationTitle("Issues")
        .searchable(text: $viewModel.dataController.filterText, tokens: $viewModel.dataController.filterTokens,
                    suggestedTokens: .constant(viewModel.dataController.suggestedFilterTokens),
                    prompt: "Filter issues, or type # to add tags") { tag in
            Text(tag.tagName)
        }
                    .toolbar(content: ContentViewToolbar.init)
    }

    init(dataControler: DataController) {
        let viewModel = ViewModel(dataController: dataControler)
        _viewModel = StateObject(wrappedValue: viewModel)

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(dataControler: .preview)
            .environmentObject(DataController(inMemory: true))
    }
}

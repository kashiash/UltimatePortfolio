//
//  IssueViewToolbar.swift
//  UltimatePortfolio
//
//  Created by Jacek Kosinski U on 27/05/2023.
//

import SwiftUI

struct IssueViewToolbar: View {

    @ObservedObject var issue: Issue
    @EnvironmentObject var dataController: DataController

    var body: some View {
        Menu {
            Button {
                UIPasteboard.general.string = issue.title
            } label: {
                Label("Copy Issue Title", systemImage: "doc.on.doc")
            }
            Button {
                issue.completed.toggle()
                dataController.save()
            } label: {
                Label(issue.completed ? "Re-open issue" : "Close issue",
                      systemImage: "bubble.left.and.exclamationmark.bubble.right")
            }
            Divider()
            Section("Tags") {
                TagsMenuView(issue: issue)
            }
        } label: {
            Label("Actions", systemImage: "ellipsis.circle")
        }
    }
}

struct IssueViewToolbar_Previews: PreviewProvider {
    static var previews: some View {
        IssueViewToolbar(issue: Issue.example)
            .environmentObject(DataController(inMemory: true))
    }
}

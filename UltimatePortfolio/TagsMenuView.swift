//
//  TagIssueView.swift
//  UltimatePortfolio
//
//  Created by Jacek Kosinski U on 27/05/2023.
//

import SwiftUI

struct TagsMenuView: View {
    @ObservedObject var issue: Issue
    @EnvironmentObject var dataController: DataController
    var body: some View {
        Menu {
            // show selected tags first
            ForEach(issue.issueTags) { tag in
                Button {
                    issue.removeFromTags(tag)
                } label: {
                    Label(tag.tagName, systemImage: "checkmark")
                }
            }

            // now show unselected tags
            let otherTags = dataController.missingTags(from: issue)

            if otherTags.isEmpty == false {
                Divider()

                Section("Add Tags") {
                    ForEach(otherTags) { tag in
                        Button(tag.tagName) {
                            issue.addToTags(tag)
                        }
                    }
                }
            }
        } label: {
            Text(issue.issueTagsList)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(nil, value: issue.issueTagsList)
        }
    }
}

struct TagIssueView_Previews: PreviewProvider {
    static var previews: some View {
        TagsMenuView(issue: Issue.example)
            .environmentObject(DataController(inMemory: true))
    }
}

//
//  IssueRow.swift
//  UltimatePortfolio
//
//  Created by Jacek Kosiński G on 26/02/2023.
//

import SwiftUI

struct IssueRow: View {
    @EnvironmentObject var dataController: DataController
    @ObservedObject var issue: Issue
    
    var body: some View {
        NavigationLink(value: issue) {
            HStack {
                Image(systemName: "exclamationmark.circle")
                    .imageScale(.large)
                    .foregroundColor(issue.completed ? .black : .red)
                    .opacity(issue.priority == 2 ? 1 : 0)

                VStack(alignment: .leading) {
                    Text(issue.issueTitle)
                        .font(.headline)
                        .lineLimit(1)
                    Text(issue.issueTaskAddress)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(issue.issueTagsList)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing) {
//                    Text(issue.issueFormattedCreationDate)
//                        .font(.subheadline)
                    Text(issue.issueFormattedCreationDate)
                        .accessibilityLabel(issue.issueFormattedCreationDate)
                        .font(.subheadline)
                    Text(issue.issueFormattedDueDate)
                        .font(.subheadline)

                    if issue.completed {
                        Text("CLOSED")
                            .font(.body.smallCaps())
                    }
                }
                .foregroundStyle(.secondary)
            }
        }
        .accessibilityHint(issue.priority == 2 ? "High priority" : "")
    }
}

struct IssueRow_Previews: PreviewProvider {
    static var previews: some View {
        IssueRow(issue: .example)
    }
}

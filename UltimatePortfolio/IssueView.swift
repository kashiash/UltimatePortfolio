//
//  IssueView.swift
//  UltimatePortfolio
//
//  Created by Jacek Kosiński G on 26/02/2023.
//

import SwiftUI

struct IssueView: View {
    @ObservedObject var issue: Issue
    @EnvironmentObject var dataController: DataController
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    TextField("Title", text: $issue.issueTitle, prompt: Text("Enter the issue title here"))
                        .font(.title)
                    Text("**Start Date:** \(issue.issueStartDate.formatted(date: .long, time: .shortened))")
                        .foregroundStyle(.primary)

                    Text("**Due Date:** \(issue.issueDueDate.formatted(date: .long, time: .shortened))")
                        .foregroundStyle(.primary)
                    Text("**Status:** \(issue.issueStatus)") //MARK LocalizedStringKey(issue.issueStatus) ??
                        .foregroundStyle(.secondary)
                    Text("**Address:** \(issue.issueTaskAddress)")
                        .foregroundStyle(.primary)


                }

                Picker("Priority", selection: $issue.priority) {
                    Text("Low").tag(Int16(0))
                    Text("Medium").tag(Int16(1))
                    Text("High").tag(Int16(2))
                }
                
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
            Section {
                VStack(alignment: .leading) {
                    Text("Basic Information")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    TextField("Description", text: $issue.issueContent, prompt: Text("Enter the issue description here"), axis: .vertical)
                    Text("**Modified:** \(issue.issueModificationDate.formatted(date: .long, time: .shortened))")
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .disabled(issue.isDeleted)
        .onReceive(issue.objectWillChange) {_ in
            dataController.queueSave()
        }
        .onSubmit (dataController.save)
        
        .toolbar{
            Menu{
                Button{
                    UIPasteboard.general.string = issue.title
                } label : {
                    Label("Copy Issue Title",systemImage: "doc.on.doc")
                }
                Button{
                    issue.completed.toggle()
                    dataController.save()
                } label: {
                    Label(issue.completed ? "Re-open issue" : "Close issue",systemImage: "bubble.left.and.exclamationmark.bubble.right")
                }
            } label: {
                Label("Actions",systemImage: "ellipsis.circle")
            }
        }
//        .onChange(of: issue) {_ in
//            dataController.queueSave()
//        }
    }
}

struct IssueView_Previews: PreviewProvider {
    static var previews: some View {
        IssueView(issue: .example)
    }
}

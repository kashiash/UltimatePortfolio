//
//  SidebarToolbar.swift
//  UltimatePortfolio
//
//  Created by Jacek Kosinski U on 27/05/2023.
//

import SwiftUI

struct SidebarToolbar: View {

    @EnvironmentObject var dataController: DataController
    @State private var showingAwards = false

    var body: some View {
        Button(action: dataController.newTag) {
            Label("Add tag", systemImage: "plus")
        }

        Button {
            showingAwards.toggle()
        } label: {
            Label("Show awards", systemImage: "rosette")
        }
        .sheet(isPresented: $showingAwards, content:AwardsView.init)

#if DEBUG
        Button {
            dataController.deleteAll()
            dataController.createSampleData()
        } label: {
            Label("ADD SAMPLES", systemImage: "flame")
        }
#endif
    }
}

struct SidebarToolbar_Previews: PreviewProvider {
    static var previews: some View {
        SidebarToolbar()
            .environmentObject(DataController(inMemory: true))
    }
}

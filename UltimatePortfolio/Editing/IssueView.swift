//
//  IssueView.swift
//  UltimatePortfolio
//
//  Created by Jacek Kosiński G on 26/02/2023.
//

import SwiftUI
import MapKit

struct IssueView: View {
    @ObservedObject var issue: Issue
    @EnvironmentObject var dataController: DataController
    @State private var coordinate: CLLocationCoordinate2D?

    var body: some View {
        TabView {
            Form {
                Section {
                    VStack(alignment: .leading) {
                        TextField("Title", text: $issue.issueTitle, prompt: Text("Enter the issue title here"))
                            .font(.title)
                        Text("**Start Date:** \(issue.issueStartDate.formatted(date: .long, time: .shortened))")
                            .foregroundStyle(.primary)
                        Text("**Due Date:** \(issue.issueDueDate.formatted(date: .long, time: .shortened))")
                            .foregroundStyle(.primary)
                        Text("**Status:** \(issue.issueStatus)") // MARK: LocalizedStringKey(issue.issueStatus) ??
                            .foregroundStyle(.secondary)
                        TextField("**Address:**", text: ($issue.issueTaskAddress),
                                  prompt: Text("Enter the address here"),
                                  axis: .vertical)
                            .foregroundStyle(.primary)
                    }

                    Picker("Priority", selection: $issue.priority) {
                        Text("Low").tag(Int16(0))
                        Text("Medium").tag(Int16(1))
                        Text("High").tag(Int16(2))
                    }

                }
                Section {
                    VStack(alignment: .leading) {
                        Text("Basic Information")
                            .font(.title2)
                            .foregroundStyle(.secondary)

                        TextField("Description", text: $issue.issueContent,
                                  prompt: Text("Enter the issue description here"),
                                  axis: .vertical)
                        Text("**Modified:** \(issue.issueModificationDate.formatted(date: .long, time: .shortened))")
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .disabled(issue.isDeleted)
            .onReceive(issue.objectWillChange) {_ in
                dataController.queueSave()
            }
            .onSubmit(dataController.save)

            .toolbar {
                IssueViewToolbar(issue: issue)
            }
            .tabItem {
                Label("Task info", systemImage: "info.circle")
            }
            if let coordinate = coordinate {
                MapView(tappedLocation: $coordinate)
                .tabItem {
                    Label("Map", systemImage: "map")
                }
            }
            if let coordinate = coordinate {
                LookAroundView(tappedLocation: $coordinate, showLookAroundView: true)
                    .tabItem {
                        Label("Around", systemImage: "binoculars")
                    }
            }
            MeView()
            .tabItem {
                Label("QRCode", systemImage: "qrcode")
            }

        }
        .onAppear {
            getCoordinate(from: issue.issueTaskAddress) { coordinate in
                self.coordinate = coordinate
            }
        }

    }

    private func getCoordinate(from address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { (placemarks, error) in
            guard let placemark = placemarks?.first, let location = placemark.location else {
                completion(nil)
                return
            }
            completion(location.coordinate)
        }
    }

    
}

struct IssueView_Previews: PreviewProvider {
    static var previews: some View {
        IssueView(issue: .example)
    }
}

//
//  LookAroundView.swift
//  UltimatePortfolio
//
//  Created by Jacek Kosinski U on 27/08/2023.
//

import MapKit
import SwiftUI

struct LookAroundView: UIViewControllerRepresentable {

    typealias UIViewControllerType = MKLookAroundViewController

    @Binding var tappedLocation: CLLocationCoordinate2D?

    @State  var showLookAroundView: Bool = true

    func makeUIViewController(context: Context) -> MKLookAroundViewController {
        return MKLookAroundViewController()
    }

    func updateUIViewController(_ uiViewController: MKLookAroundViewController, context: Context) {
        if let tappedLocation = tappedLocation {
            Task {
                if let scene = await getScene(tappedLocation: .init(latitude: tappedLocation.latitude, longitude: tappedLocation.longitude)) {
                    withAnimation {
                        self.showLookAroundView = true
                        uiViewController.scene = scene
                    }
                } else {
                    withAnimation {
                        self.showLookAroundView = false
                    }
                    return
                }
            }
        }
    }

    func getScene(tappedLocation: CLLocationCoordinate2D?) async -> MKLookAroundScene? {
        if let lat = tappedLocation?.latitude, let long = tappedLocation?.longitude {
            let sceneRequest = MKLookAroundSceneRequest(coordinate: .init(latitude: lat, longitude: long))

            do {
                return try await sceneRequest.scene
            } catch {
                print(error)
                return nil
            }
        } else {
            return nil
        }
    }
}


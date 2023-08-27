//
//  MapView.swift
//  UltimatePortfolio
//
//  Created by Jacek Kosinski U on 27/08/2023.
//

import MapKit
import CoreLocation
import SwiftUI

struct MapView: UIViewRepresentable {
    typealias  UIViewType = MKMapView

    @Binding var tappedLocation: CLLocationCoordinate2D?

    @StateObject var locationManager = LocationManager()

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(MapViewCoordinator.tappedOnMap(_:)))

        mapView.addGestureRecognizer(tapGesture)


        if let locationCoorinate = tappedLocation {

            let annotation = MKPointAnnotation()
            annotation.coordinate = .init(latitude:locationCoorinate.latitude,longitude: locationCoorinate.longitude)
            self.tappedLocation = locationCoorinate

            mapView.removeAnnotations(mapView.annotations)
            mapView.addAnnotation(annotation)

            if let userLocation = locationManager.userLocation {
                let userAnnotation = MKPointAnnotation()
                annotation.coordinate = .init(latitude:userLocation.latitude,longitude: userLocation.longitude)
                mapView.addAnnotation(userAnnotation)
            }
        }

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {

        if uiView.delegate != nil  {return}
        if let tappedLocation = tappedLocation {
            uiView.setRegion(.init(center: tappedLocation, latitudinalMeters: 400, longitudinalMeters: 400), animated: false)
            uiView.delegate = context.coordinator
        } else {
        }
    }

    func makeCoordinator() -> MapViewCoordinator {
       return MapViewCoordinator(self, tappedLocation: $tappedLocation)
    }
}

final class MapViewCoordinator: NSObject, MKMapViewDelegate {
    @Binding var tappedLocation: CLLocationCoordinate2D?

    var parent: MapView

    init(_ mapView: MapView, tappedLocation: Binding<CLLocationCoordinate2D?>) {
        self.parent = mapView
        self._tappedLocation = tappedLocation
    }

    @objc func tappedOnMap(_ sender:UITapGestureRecognizer){
        guard let mapView = sender.view as? MKMapView else { return }

        let touchLocation = sender.location(in: sender.view)
        let locationCoorinate = mapView.convert(touchLocation,toCoordinateFrom: sender.view)

        let annotation = MKPointAnnotation()
        annotation.coordinate = .init(latitude:locationCoorinate.latitude,longitude: locationCoorinate.longitude)
        self.tappedLocation = locationCoorinate

        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(annotation)
    }
}

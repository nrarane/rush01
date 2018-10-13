//
//  ViewController.swift
//  Maps
//
//  Created by Gaolatlhwe SEBAETSE on 2018/10/13.
//  Copyright © 2018 Gaolatlhwe SEBAETSE. All rights reserved.
//

import UIKit
import MapKit

struct Location {
    var latitude:Double
    var longitude:Double
}

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate {
    
    
    @IBOutlet weak var mapView: MKMapView!

    
    let locationManager = CLLocationManager()

    @IBAction func searchButton(_ sender: Any) {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = self
        searchController.searchBar.delegate = self
        present(searchController, animated: true, completion: nil)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        //IGNORE USER
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        self.view.addSubview(activityIndicator)
        
        //HIDE SEARCH BAR
        searchBar.resignFirstResponder()
        dismiss(animated: true, completion: nil)
        
        //REQUEST
        let searchRequest = MKLocalSearchRequest()
        searchRequest.naturalLanguageQuery = searchBar.text
        
        let activeSearch = MKLocalSearch(request: searchRequest)
        activeSearch.start {(response, error) in
            
            activityIndicator.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
            
            if response == nil
            {
                print("error")
                let alert = UIAlertController(title: "Map", message: "There was an error with the request", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true)
            }
            else
            {
                let annotations = self.mapView.annotations
                self.mapView.removeAnnotations(annotations)
                
                let latitude = response?.boundingRegion.center.latitude
                let longitude = response?.boundingRegion.center.longitude
                
                let searchLocation = Location(latitude: latitude!, longitude: longitude!);
                let destLocation = Location(latitude: self.mapView.userLocation.coordinate.latitude, longitude:self.mapView.userLocation.coordinate.longitude );
                
                self.getDirections(departureLocation: searchLocation, destinationLocation:destLocation)
                let annotation = MKPointAnnotation()
                annotation.title = searchBar.text
                annotation.coordinate = CLLocationCoordinate2DMake(latitude!, longitude!)
                self.mapView.addAnnotation(annotation)
                
                let span = MKCoordinateSpanMake(0.002, 0.002)
                let coordinate = CLLocationCoordinate2DMake(latitude!, longitude!)
                let region = MKCoordinateRegionMake(coordinate, span)
                self.mapView.setRegion(region, animated: true)
            }
        }
    }
    
    //SELECTING MAP TYPE
    @IBAction func mapType(_ sender: UISegmentedControl) {
        switch sender.titleForSegment(at: sender.selectedSegmentIndex)! {
        case "Standard":
            mapView.mapType = .standard;
        case "Satellite":
            mapView.mapType = .satellite;
        case "Hybrid":
            mapView.mapType = .hybrid;
        default:
            break ;
        }
    }
    
    
    //USER LOCATION
    @IBAction func locateMe(_ sender: UIButton) {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            let span = MKCoordinateSpanMake(0.004, 0.004)
            let myLocation = CLLocationCoordinate2DMake(mapView.userLocation.coordinate.latitude, mapView.userLocation.coordinate.longitude)
            let region = MKCoordinateRegionMake(myLocation, span)
            mapView.setRegion(region, animated: true)
            self.mapView.showsUserLocation = true;
            mapView.setCenter(mapView.userLocation.coordinate, animated: true)
        }
        else {
            mapView.showsUserLocation = false
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    //DIRECTION FIND
    @IBAction func direction(_ sender: UIBarButtonItem) {
        
        //getDirections(departureLocation: myLocation, destinationLocation: <#T##Location#>)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.selectedIndex = 1
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        locationManager.startUpdatingLocation()
        self.mapView.delegate = self    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getDirections(departureLocation: Location, destinationLocation: Location){
        
        print("Departure location: \(departureLocation.latitude),\(departureLocation.longitude)");
        print("Destination location: \(destinationLocation.latitude),\(destinationLocation.longitude)");
        
        let sourceLocation = CLLocationCoordinate2D(latitude: departureLocation.latitude, longitude: departureLocation.longitude)
        let destinationLocation = CLLocationCoordinate2D(latitude: destinationLocation.latitude, longitude: destinationLocation.longitude)
        
        let sourcePlaceMark = MKPlacemark(coordinate: sourceLocation)
        let destinationPlaceMark = MKPlacemark(coordinate: destinationLocation)
        
        let directionRequest = MKDirectionsRequest()
        directionRequest.source = MKMapItem(placemark: sourcePlaceMark)
        directionRequest.destination = MKMapItem(placemark: destinationPlaceMark)
        directionRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (response, error) in
            guard let directionResonse = response else {
                if let error = error {
                    print("we have error getting directions==\(error.localizedDescription)")
                    let alert = UIAlertController(title: "Error!", message: "No Direct Route To Your Destination Address Can Be Found!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true)
                }
                return
            }
            
            let route = directionResonse.routes[0]
            self.mapView.add(route.polyline, level: .aboveRoads)
            
            let rect = route.polyline.boundingMapRect
            self.mapView.setRegion(MKCoordinateRegionForMapRect(rect), animated: true)
        }
    }
    
    //MARK:- MapKit delegates
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 4.0
        return renderer
    }
}

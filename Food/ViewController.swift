//
//  ViewController.swift
//  Food
//
//  Created by Wei Mun Yap on 24/01/2016.
//  Copyright © 2016 UrbanVillage. All rights reserved.
//

import UIKit
import MapKit
import RealmSwift

class ViewController: UIViewController, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    /// Outlet for the map view (top)
    @IBOutlet var mapView:MKMapView?
    
    /// Outlet for the table view (bottom)
    @IBOutlet var tableView:UITableView?
    
    /// Outlet for the search button
    @IBOutlet weak var searchButton: UIButton!
    
    /// Location manager to get the user's location
    var locationManager: CLLocationManager?
    
    /// Convenient property to remember the last location
    var lastLocation:CLLocation?;
    var viewLocation:CLLocation?;
    
    /// Stores venues from Realm as a Results instance, use if not using non-lazy / Realm sorting
    var allVenues:Results<Venue>?;
    
    /// Stores venues from Realm, as a non-lazy list
    var mapVenues:[Venue]?;
    
    /// Span in meters for map view and data filtering
    let distanceSpan:Double = 1000
    var center: CLLocationCoordinate2D?
    var isInitialized = false
    
    override func viewDidLoad() {
        super.viewDidLoad();
        // This code will send a notification to every part of the app that listens to it. It’s the de facto notification mechanism in apps, and it’s very effective for events that affect multiple parts of your app. Consider that you’ve just received new data from Foursquare. You may want to update the table view that shows that data, or some other part of your code.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("onVenuesUpdated:"), name: API.notifications.venuesUpdated, object: nil);
        
        // All your other setup code
        let mapDragRecognizer = UIPanGestureRecognizer(target: self, action: "didDragMap:")
        mapDragRecognizer.delegate = self
        self.mapView!.addGestureRecognizer(mapDragRecognizer)
        
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated);
        
        if let tableView = self.tableView {
            tableView.delegate = self
            tableView.dataSource = self
        }
        
        if let mapView = self.mapView {
            // The current class becomes delegate of mapView if it isn’t empty.
            mapView.delegate = self;
        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if locationManager == nil {
            locationManager = CLLocationManager();
            
            locationManager!.delegate = self;
            locationManager!.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
            locationManager!.requestAlwaysAuthorization();
            locationManager!.distanceFilter = 20; // Don't send location updates with a distance smaller than 50 meters between them
            // This will cause the location manager to poll for a GPS location, and call a method on the delegate telling it the new GPS location.
            locationManager!.startUpdatingLocation();
        }
        mapView!.showsUserLocation = true
        
    }

    
    // For the UIPanGestureRecognizer to work with the already existing gesture recognizers in MKMapView.
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // Detect either the "drag ended" or "drag began" state in your selector.
    func didDragMap(gestureRecognizer: UIGestureRecognizer) {
        if (gestureRecognizer.state == UIGestureRecognizerState.Began) {
//            print("Map drag began")
        }
        
        if (gestureRecognizer.state == UIGestureRecognizerState.Ended) {
            
            searchButton.hidden = false
            
        }
    }
    
    
    @IBAction func searchTapped(sender: AnyObject) {
        
        let viewLocation = CLLocation(latitude: (mapView?.centerCoordinate.latitude)!, longitude: (mapView?.centerCoordinate.longitude)!)
        let mapDisplayDistance = calculateDistanceFromMap((mapView?.region)!)
        
        
        // Pulls data from Foursquare API(~ 1x the view region size) and re-populate map.
        refreshVenues(viewLocation, distanceSpan: mapDisplayDistance)
        populate(viewLocation, distanceSpan: mapDisplayDistance * 2.0)
        
        searchButton.hidden = true
        
        self.mapView!.removeOverlays(self.mapView!.overlays)
    }
    
    
    // Calculates the maximum of lattitude and longitude distance in meters for a map region.
    func calculateDistanceFromMap(region:MKCoordinateRegion) -> Double {
        
        let span = region.span
        let center = region.center
        
        let loc1 = CLLocation(latitude: center.latitude - span.latitudeDelta * 0.5, longitude: center.longitude)
        let loc2 = CLLocation(latitude: center.latitude + span.latitudeDelta * 0.5, longitude: center.longitude)
        let loc3 = CLLocation(latitude: center.latitude, longitude: center.longitude - span.longitudeDelta * 0.5)
        let loc4 = CLLocation(latitude: center.latitude, longitude: center.longitude + span.longitudeDelta * 0.5)
        
        let metersInLatitude = loc1.distanceFromLocation(loc2)
        let metersInLongitude = loc3.distanceFromLocation(loc4)
        
        return max(metersInLatitude,metersInLongitude)
    }
    
    
    // Turn a CLLocation instance into a top-left and bottom-right coordinate, based on a region distance span. If distanceSpan is not passed in, the function will calculate from the mapView's current displayed region.
    func calculateCoordinatesWithRegion(location:CLLocation, distanceSpan:Double?) -> (CLLocationCoordinate2D, CLLocationCoordinate2D) {
        
        var region: MKCoordinateRegion
        
        if let distanceSpan = distanceSpan {
            region = MKCoordinateRegionMakeWithDistance(location.coordinate, distanceSpan, distanceSpan);
        } else {
            region = (mapView?.region)!
        }
        
        var start:CLLocationCoordinate2D = CLLocationCoordinate2D();
        var stop:CLLocationCoordinate2D = CLLocationCoordinate2D();
        
        start.latitude  = region.center.latitude  + (region.span.latitudeDelta  / 2.0);
        start.longitude = region.center.longitude - (region.span.longitudeDelta / 2.0);
        stop.latitude   = region.center.latitude  - (region.span.latitudeDelta  / 2.0);
        stop.longitude  = region.center.longitude + (region.span.longitudeDelta / 2.0);
        
        return (start, stop);
    }
    
    // All location data in the app originates from the locationManager:didUpdateToLocation:fromLocation method. It is the only place where a CLLocation instance enters the app, based on data from the GPS hardware.
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        if !isInitialized {
            
            // Set flag to true so that it's only called once in here
            isInitialized = true
            
            // setRegion sets both the center coordinate, and the "zoom level"
            let region = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, distanceSpan, distanceSpan);
            self.mapView!.setRegion(region, animated: true)
            
            // Reload map and table
            populate(newLocation, distanceSpan: distanceSpan * 2.0)
        }
        
        lastLocation = newLocation
    }
    
    
    func populate(location: CLLocation , distanceSpan:Double?) {
        
        // Refresh Venue property
        allVenues = try! Realm().objects(Venue)
        
        // Convenience method to calculate the top-left and bottom-right GPS coordinates based on region (defined with distanceSpan).
        let (start, stop) = calculateCoordinatesWithRegion(location, distanceSpan: distanceSpan)
        
        // Set up a predicate that ensures the fetched venues are within the region of the user location.
        let predicate = NSPredicate(format: "latitude < %f AND latitude > %f AND longitude > %f AND longitude < %f", start.latitude, stop.latitude, start.longitude, stop.longitude)
        
        
        mapView!.removeAnnotations(mapView!.annotations)
        mapVenues = allVenues!.filter(predicate).sort {
            location.distanceFromLocation($0.coordinate) < location.distanceFromLocation($1.coordinate);
        }
        // Throw the found venues on the map kit as annotations.
        for venue in mapVenues! {
            let annotation = FoodAnnotation(title: venue.name, subtitle: venue.address, coordinate: CLLocationCoordinate2D(latitude: Double(venue.latitude), longitude: Double(venue.longitude)));
            
            mapView?.addAnnotation(annotation)
        }
        
        // RELOAD ALL DATA to be show in the table.
        tableView?.reloadData()
        
    }
    


    // We want to call refreshVenues independently from method locationManager:didUpdateToLocation:fromLocation we need to store the location data separate from that method. This calls Foursquare to get data.
    func refreshVenues(location: CLLocation?, distanceSpan:Double = 1000) {
        // If location isn't nil, set it as the last location.
//        if location != nil {
//            lastLocation = location
//        }

        // If the last location isn't nil, i.e. if a lastLocation was set OR parameter location wasn't nil.
        if let location = location {
            // Make a call to Foursquare to get data.
            FoodAPI.sharedInstance.getFoodShopsWithLocation(location,distanceSpan: distanceSpan)
        }
        
//        // Reset lastLocation, otherwise every map drag will refresh venues automatically based on last location
//        lastLocation = nil
    }
    
    func onVenuesUpdated(notification:NSNotification) {
        // When new data from Foursquare comes in, reload from local Realm.
        // The method does not include location data, and does not provide the getDataFromFoursquare parameter. That parameter is false by default, so no data from Foursquare is requested. You get it: this would in turn trigger an infinite loop in which the return of data causes a request for data ad infinitum.
        refreshVenues(nil);
    }
    
    
    func displayRoute(source:CLLocation,destination:CLLocation) {
        
        let overlays = self.mapView!.overlays
        self.mapView!.removeOverlays(overlays)
        
        let request = MKDirectionsRequest()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: source.coordinate.latitude, longitude: source.coordinate.longitude), addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: destination.coordinate.latitude, longitude: destination.coordinate.longitude), addressDictionary: nil))
        request.requestsAlternateRoutes = true
        request.transportType = MKDirectionsTransportType.Walking
        
        let directions = MKDirections(request: request)
        
        // Sets up a closure to run when the directions come back that adds them as overlays to the map.
        directions.calculateDirectionsWithCompletionHandler { [unowned self] response, error in
            guard let unwrappedResponse = response else { return }
    
            for route in unwrappedResponse.routes {
                self.mapView!.addOverlay(route.polyline,level: MKOverlayLevel.AboveRoads)
//                self.mapView!.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning();
    }
}

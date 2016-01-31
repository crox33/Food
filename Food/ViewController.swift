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

class ViewController: UIViewController, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate {
    /// Outlet for the map view (top)
    @IBOutlet var mapView:MKMapView?
    
    /// Outlet for the table view (bottom)
    @IBOutlet var tableView:UITableView?
    
    /// Location manager to get the user's location
    var locationManager: CLLocationManager?
    
    /// Convenient property to remember the last location
    var lastLocation:CLLocation?;
    
    /// Stores venues from Realm as a Results instance, use if not using non-lazy / Realm sorting
    //var venues:Results<Venue>?;
    
    /// Stores venues from Realm, as a non-lazy list
    var venues:[Venue]?;
    
    /// Span in meters for map view and data filtering
    let distanceSpan:Double = 2000;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        // This code will send a notification to every part of the app that listens to it. It’s the de facto notification mechanism in apps, and it’s very effective for events that affect multiple parts of your app. Consider that you’ve just received new data from Foursquare. You may want to update the table view that shows that data, or some other part of your code.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("onVenuesUpdated:"), name: API.notifications.venuesUpdated, object: nil);
        
//        print(Realm.Configuration.defaultConfiguration.path)
    }
    
    func calculateCoordinatesWithRegion(location:CLLocation) -> (CLLocationCoordinate2D, CLLocationCoordinate2D) {
        let region = MKCoordinateRegionMakeWithDistance(location.coordinate, distanceSpan, distanceSpan);
        
        var start:CLLocationCoordinate2D = CLLocationCoordinate2D();
        var stop:CLLocationCoordinate2D = CLLocationCoordinate2D();
        
        start.latitude  = region.center.latitude  + (region.span.latitudeDelta  / 2.0);
        start.longitude = region.center.longitude - (region.span.longitudeDelta / 2.0);
        stop.latitude   = region.center.latitude  - (region.span.latitudeDelta  / 2.0);
        stop.longitude  = region.center.longitude + (region.span.longitudeDelta / 2.0);
        
        return (start, stop);
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
            locationManager!.distanceFilter = 50; // Don't send location updates with a distance smaller than 50 meters between them
            // This will cause the location manager to poll for a GPS location, and call a method on the delegate telling it the new GPS location.
            locationManager!.startUpdatingLocation();
        }
        mapView!.showsUserLocation = true
    }
    
    // All location data in the app originates from the locationManager:didUpdateToLocation:fromLocation method. It is the only place where a CLLocation instance enters the app, based on data from the GPS hardware.
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        if let mapView = self.mapView {
            // setRegion sets both the center coordinate, and the "zoom level"
            let region = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, distanceSpan * 2.0, distanceSpan * 2.0);
            mapView.setRegion(region, animated: true)
            
            // Calls refreshVenues with the GPS location of the user. Additionally, it tells the API to request data from Foursquare. Essentially, every time the user moves new data is requested from Foursquare. Thanks to the settings that only happens once every 50 meters. And thanks to the notification center, the map is updated!
            refreshVenues(newLocation, getDataFromFoursquare: true)
        }
    }
    
    // We want to call refreshVenues independently from method locationManager:didUpdateToLocation:fromLocation we need to store the location data separate from that method.
    func refreshVenues(location: CLLocation?, getDataFromFoursquare:Bool = false) {
        // If location isn't nil, set it as the last location
        if location != nil {
            lastLocation = location
        }
        
        // If the last location isn't nil, i.e. if a lastLocation was set OR parameter location wasn't nil.
        if let location = lastLocation {
            // Make a call to Foursquare to get data.
            if getDataFromFoursquare == true {
                FoodAPI.sharedInstance.getFoodShopsWithLocation(location);
            }
            
            // Convenience method to calculate the top-left and bottom-right GPS coordinates based on region (defined with distanceSpan).
            let (start, stop) = calculateCoordinatesWithRegion(location);
            
            // Set up a predicate that ensures the fetched venues are within the region.
            let predicate = NSPredicate(format: "latitude < %f AND latitude > %f AND longitude > %f AND longitude < %f", start.latitude, stop.latitude, start.longitude, stop.longitude);
            
            // Initialize Realm (while supressing error handling).
            let realm = try! Realm();
            
            // Get all the objects of class Venue from Realm. Note that the "sort" isn't part of Realm, it's Swift, and it defeats Realm's lazy loading nature!
            venues = realm.objects(Venue).filter(predicate).sort {
                // The sort method takes one argument: a closure that determines the order of two unsorted objects. By returning true or false, the closure indicates which of the two objects precedes the other. In your code, you determine the order based on distance from the user’s location. This is where the coordinate computed property comes into play. The $0 and $1 are shorthands for the two unsorted objects. Basically, the method sorts the venues on distance from the user’s location (closer = higher).
                location.distanceFromLocation($0.coordinate) < location.distanceFromLocation($1.coordinate);
            }
            
            // Throw the found venues on the map kit as annotations
            for venue in venues! {
                let annotation = FoodAnnotation(title: venue.name, subtitle: venue.address, coordinate: CLLocationCoordinate2D(latitude: Double(venue.latitude), longitude: Double(venue.longitude)));
                
                mapView?.addAnnotation(annotation);
            }
            
            // RELOAD ALL DATA!!!
            tableView?.reloadData();
        }
    }
    

    
    
    func onVenuesUpdated(notification:NSNotification) {
        // When new data from Foursquare comes in, reload from local Realm.
        // The method does not include location data, and does not provide the getDataFromFoursquare parameter. That parameter is false by default, so no data from Foursquare is requested. You get it: this would in turn trigger an infinite loop in which the return of data causes a request for data ad infinitum.
        refreshVenues(nil);
    }
    
    
    // Ensures that the annotations you add to the map are actually shown. So, when the map view is ready to display pins it will call the mapView:viewForAnnotation: method when a delegate is set and thus the app will get here.
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        // Check if the annotation isn’t accidentally the user blip.
        if annotation.isKindOfClass(MKUserLocation) {
            return nil;
        }
        
        // Dequeue a pin.
        var view = mapView.dequeueReusableAnnotationViewWithIdentifier("annotationIdentifier");
        
        // If no pin was dequeued, create a new one.
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "annotationIdentifier");
        }
        // Set that the pin can show a callout (little blurb with information).
        view?.canShowCallout = true
        
        return view
    }
    
    // Determines how many cells the table view has.
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // When venues is nil, this will return 0 (nil-coalescing operator ??)
        return venues?.count ?? 0;
    }
    
    // Determines how many sections the table view has.
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1;
    }
    
    // The method tableView:cellForRowAtIndexPath: is called when the table view code wants a table view cell. You can use the method to customize your table view cells. It’s easier than subclassing!
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Attempt to dequeue a cell.
        var cell = tableView.dequeueReusableCellWithIdentifier("cellIdentifier");
        
        // If no cell exists, create a new one with style Subtitle.
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "cellIdentifier");
        }
        
        // If venues contains an item for index indexPath.row, assign it to constant venue. Use the data to populate the textLabel and detailTextLabel of the cell.
        if let venue = venues?[indexPath.row] {
            cell!.textLabel?.text = venue.name;
            cell!.detailTextLabel?.text = venue.address;
        }
        
        return cell!;
    }
    
    // Delegate method that’s called when the user taps a cell.
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // When the user taps a table view cell, attempt to pan to the pin in the map view
        if let venue = venues?[indexPath.row] {
            let region = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2D(latitude: Double(venue.latitude), longitude: Double(venue.longitude)), distanceSpan, distanceSpan)
            mapView?.setRegion(region, animated: true)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning();
    }
}


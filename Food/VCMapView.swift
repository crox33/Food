//
//  VCMapView.swift
//  Food
//
//  Created by Wei Mun Yap on 04/02/2016.
//  Copyright © 2016 UrbanVillage. All rights reserved.
//

import Foundation
import MapKit
import UIKit

extension ViewController: MKMapViewDelegate {
    
    
    // Ensures that the annotations you add to the map are actually shown. So, when the map view is ready to display pins it will call the mapView:viewForAnnotation: method when a delegate is set and thus the app will get here.
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        // Check if the annotation isn’t accidentally the user blip.
//        if annotation.isKindOfClass(MKUserLocation) {
//            return nil;
//        }
        
        if let annotation = annotation as? FoodAnnotation {
            var view: MKPinAnnotationView
            
            //  Map views are set up to reuse annotation views when some are no longer visible. So the code first checks to see if a reusable annotation view is available before creating a new one.
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier("annotationIdentifier") as? MKPinAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
                
            } else {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "annotationIdentifier")
                view.animatesDrop = false
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
//                view.rightCalloutAccessoryView = UIButton(type: .InfoLight)
                
            }
            return view
        }
        
        return nil
    }
    
    
    // When user taps the map annotation pin.
    func mapView(mapView: MKMapView,didSelectAnnotationView view: MKAnnotationView){
        
        
        let destinationLocation = CLLocation(latitude: view.annotation!.coordinate.latitude, longitude: view.annotation!.coordinate.longitude)
        displayRoute(lastLocation!, destination: destinationLocation)
        
        // Select the corresponding row from table view.
        for var i = 0; i<mapVenues?.count; i++ {
            if view.annotation?.coordinate.latitude == Double(mapVenues![i].latitude) && view.annotation?.coordinate.longitude == Double(mapVenues![i].longitude) {
                
                tableView?.selectRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0), animated: true, scrollPosition: UITableViewScrollPosition(rawValue: 1)!)
                break
            }
        }
        
        

    }
    
    
    
    
    // When the user taps the callout info button after the map annotation pin.
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        /* Grab the FoodAnnotation object that this tap refers to and then launch the Maps app by creating an associated MKMapItem and calling openInMapsWithLaunchOptions on the map item.
        Notice you’re passing a dictionary to this method. This allows you to specify a few different options; here the DirectionModeKeys is set to Walking. This will make the Maps app try to show walking directions from the user’s current location to this pin.
        */
        let location = view.annotation as! FoodAnnotation
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking]
        location.mapItem().openInMapsWithLaunchOptions(launchOptions)
        
    }
    
    // When the map has changed, re-populate TableView based on new map region and select the row if there are selected annotations
//    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
//        center = mapView.centerCoordinate
//        
//        let mapLocation = CLLocation(latitude: center!.latitude, longitude: center!.longitude)
//        populate(mapLocation, distanceSpan: nil)
//        populate(mapLocation, distanceSpan: nil)
//        
//        let annotations = mapView.selectedAnnotations
//        
//        if annotations.count > 0{
//            for annotation in annotations {
//              
//                for var i = 0; i<mapVenues?.count; i++ {
//                    
//                    if annotation.coordinate.latitude == Double(mapVenues![i].latitude) && annotation.coordinate.longitude == Double(mapVenues![i].longitude) {
//                        
//                        tableView?.selectRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0), animated: true, scrollPosition: UITableViewScrollPosition(rawValue: 1)!)
//                        break
//                    }
//                    
//                }
//            }
//        }
//    }
    
    // To make overlays draw.
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = UIColor.blueColor().colorWithAlphaComponent(0.5)
        renderer.lineWidth = 6
        return renderer
    }
    
}
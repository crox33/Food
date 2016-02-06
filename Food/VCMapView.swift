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
                view.rightCalloutAccessoryView = UIButton(type: .InfoLight)
                
                //            let location = view.annotation as! FoodAnnotation
                
                print(inMapDisplayVenues?.count)
                //
                //            for var i = 0; i<inMapDisplayVenues?.count; i++ {
                //                print(i)
                //                if location.coordinate.latitude == Double(inMapDisplayVenues![i].latitude) && location.coordinate.longitude == Double(inMapDisplayVenues![i].longitude) {
                //                    print("success")
                //                    tableView?.selectRowAtIndexPath(NSIndexPath(index: i), animated: true, scrollPosition: UITableViewScrollPosition(rawValue: 2)!)
                //                    break
                //                }
                //                
                //            }
            
            }
            return view
        }
        
        return nil
    }
    
    
    // When the user taps a map annotation pin, the callout shows an info button. If the user taps this info button, this method is called.
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        /* Grab the FoodAnnotation object that this tap refers to and then launch the Maps app by creating an associated MKMapItem and calling openInMapsWithLaunchOptions on the map item.
        Notice you’re passing a dictionary to this method. This allows you to specify a few different options; here the DirectionModeKeys is set to Walking. This will make the Maps app try to show walking directions from the user’s current location to this pin.
        */
        let location = view.annotation as! FoodAnnotation
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking]
        location.mapItem().openInMapsWithLaunchOptions(launchOptions)
        
    }
    
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        center = mapView.centerCoordinate
    }
    
}
//
//  VCTableView.swift
//  Food
//
//  Created by Wei Mun Yap on 04/02/2016.
//  Copyright © 2016 UrbanVillage. All rights reserved.
//

import Foundation
import UIKit
import MapKit

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    
    // Determines how many cells the table view has.
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // When venues is nil, this will return 0 (nil-coalescing operator ??)
        return mapVenues?.count ?? 0;
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
        if let venue = mapVenues?[indexPath.row] {
            cell!.textLabel?.text = venue.name;
            cell!.detailTextLabel?.text = venue.address;
        }
        
        return cell!;
    }
    
    // Delegate method that’s called when the user taps a cell.
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // When the user taps a table view cell, attempt to pan to the pin in the map view and trigger callout on the pin
        if let venue = mapVenues?[indexPath.row] {
//            let region = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2D(latitude: Double(venue.latitude), longitude: Double(venue.longitude)), distanceSpan/2.0, distanceSpan/2.0)
//            mapView?.setRegion(region, animated: true)
            
            for annotation in mapView!.annotations {
                if annotation.coordinate.latitude == Double(venue.latitude) && annotation.coordinate.longitude == Double(venue.longitude) {
                    mapView?.selectAnnotation(annotation, animated: true)
                    break
                }
            }
        }
    }
    
}
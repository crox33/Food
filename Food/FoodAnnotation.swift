//
//  FoodAnnotation.swift
//  Food
//
//  Created by Wei Mun Yap on 24/01/2016.
//  Copyright © 2016 UrbanVillage. All rights reserved.
//

import Foundation
import MapKit
import Contacts


// New class called FoodAnnotation that inherits from NSObject and implements the MKAnnotation protocol. Before you can use a class as an annotation, it needs to conform to the annotation protocol.
class FoodAnnotation: NSObject, MKAnnotation {
    
    // These properties are required to be part of the class, because the protocol dictates so.
    let title:String?;
    let subtitle:String?;
    let coordinate: CLLocationCoordinate2D;
    
    // Filling up the class properties based on the method parameters.
    init(title: String?, subtitle:String?, coordinate: CLLocationCoordinate2D) {
        self.title = title;
        self.subtitle = subtitle;
        self.coordinate = coordinate;
        
        super.init();
    }
    
    // Annotation callout info button opens this mapItem in Maps app.
    func mapItem() -> MKMapItem {
        let addressDict = [String(CNPostalAddressStreetKey): self.subtitle!]
        let place = MKPlacemark(coordinate: self.coordinate, addressDictionary: addressDict)
        
        let mapItem = MKMapItem(placemark: place)
        mapItem.name = self.title
        
        return mapItem
    }
}
//
//  Venue.swift
//  Food
//
//  Created by Wei Mun Yap on 24/01/2016.
//  Copyright © 2016 UrbanVillage. All rights reserved.
//

import Foundation
import RealmSwift
import MapKit

// The Das Quadrat library sends a message to Foursquare, waits for it to come back, and then invokes the closure you wrote to process the data.
class Venue: Object {
    // Realm relies on Objective-C runtime. Swift 2.0 has it's own runtime.
    dynamic var id:String = "";
    dynamic var name:String = "";
    
    dynamic var latitude:Float = 0;
    dynamic var longitude:Float = 0;
    
    dynamic var address:String = "";
    
    dynamic var url:String = "";
    
    // It’s a computed property. It won’t be saved with Realm because it can’t store computed properties. It’s like a method, but then it’s accessed as if it were a property.
    var coordinate:CLLocation {
        return CLLocation(latitude: Double(latitude), longitude: Double(longitude));
    }
    
    // This is a new method, which is overriden from the superclass Object. It’s a customization point and you use it to indicate the primary key to Realm.
    override static func primaryKey() -> String? {
        return "id";
    }
}
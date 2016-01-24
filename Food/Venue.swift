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

class Venue: Object
{
    dynamic var id:String = "";
    dynamic var name:String = "";
    
    dynamic var latitude:Float = 0;
    dynamic var longitude:Float = 0;
    
    dynamic var address:String = "";
    
    var coordinate:CLLocation {
        return CLLocation(latitude: Double(latitude), longitude: Double(longitude));
    }
    
    override static func primaryKey() -> String?
    {
        return "id";
    }
}
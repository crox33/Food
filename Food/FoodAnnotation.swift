//
//  FoodAnnotation.swift
//  Food
//
//  Created by Wei Mun Yap on 24/01/2016.
//  Copyright © 2016 UrbanVillage. All rights reserved.
//

import Foundation
import MapKit

class FoodAnnotation: NSObject, MKAnnotation
{
    let title:String?;
    let subtitle:String?;
    let coordinate: CLLocationCoordinate2D;
    
    init(title: String?, subtitle:String?, coordinate: CLLocationCoordinate2D)
    {
        self.title = title;
        self.subtitle = subtitle;
        self.coordinate = coordinate;
        
        super.init();
    }
}
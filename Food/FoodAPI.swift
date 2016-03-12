//
//  FoodAPI.swift
//  Food
//
//  Created by Wei Mun Yap on 24/01/2016.
//  Copyright © 2016 UrbanVillage. All rights reserved.
//

import Foundation
import QuadratTouch
import MapKit
import RealmSwift

struct API {
    struct notifications {
        static let venuesUpdated = "venues updated";
    }
}

// FoodAPI. It’s a pure Swift class, and doesn’t subclass NSObject!
class FoodAPI {
    // Declare a static class constant called sharedInstance, of type FoodAPI. This “shared instance” is only accessible through the class FoodAPI, and is instantiated when the app starts (eager loading).
    static let sharedInstance = FoodAPI();
    // Declare a class property called session, of type Session? (from Das Quadrat).
    var session:Session?;
    
    init() {
        // Initialize the Foursquare client.
        // My clientID and clientSecret from foursquare.
        let client = Client(clientID: "JES1WENK2G1PBDF5HKLDXTVB5TEJY5RK5JBEDEFCWQZR532L", clientSecret: "GRN5QITEA315MRE3VPR2HTGM2BPOI53S22UBSJE0WDEPMMF0", redirectURL: "");
        
        let configuration = Configuration(client:client);
        Session.setupSharedSessionWithConfiguration(configuration);
        
        self.session = Session.sharedSession();
    }
    
    func getFoodShopsWithLocation(location:CLLocation, distanceSpan:Double) {
        if let session = self.session {
            // Provide the user location and the hard-coded Foursquare category ID for "Foodshops"
            var parameters = location.parameters();
            parameters += [Parameter.categoryId: "4d4b7105d754a06374d81259"];
            parameters += [Parameter.radius: "\(distanceSpan)"];
            parameters += [Parameter.limit: "50"];
            
            // Start a "search", i.e. an async call to Foursquare that should return venue data.
            let searchTask = session.venues.search(parameters) {
                    (result) -> Void in
                
                // When the data from the HTTP API is returned to the app.
                    if let response = result.response {
                        // When response["venues"] is not nil.
                        if let venues = response["venues"] as? [[String: AnyObject]] {
                            // By creating your own autorelease pool, you can influence the discarding of released memory and avoid being stuck for free memory.
                            autoreleasepool {
                                    let realm = try! Realm(); // Note: no error handling
                                    realm.beginWrite();
                                    
                                    for venue:[String: AnyObject] in venues {
                                        let venueObject:Venue = Venue();
                                        
                                        // When venue contains a key id, attempt to cast it to String and if that succeeds, assign it to the id property of venueObject.
                                        if let id = venue["id"] as? String {
                                            venueObject.id = id;
                                        }
                                        
                                        if let name = venue["name"] as? String {
                                            venueObject.name = name;
                                        }
                                        
                                        if  let location = venue["location"] as? [String: AnyObject] {
                                            if let longitude = location["lng"] as? Float {
                                                venueObject.longitude = longitude;
                                            }
                                            
                                            if let latitude = location["lat"] as? Float {
                                                venueObject.latitude = latitude;
                                            }
                                            
                                            if let formattedAddress = location["formattedAddress"] as? [String] {
                                                venueObject.address = formattedAddress.joinWithSeparator(" ");
                                            }
                                        }
                                        
                                        if let url = venue["url"] as? String {
                                            venueObject.url = url
                                        }
                                        
                                        
                                        // When this object already exists, Realm should overwrite it with the new data.
                                        realm.add(venueObject, update: true);
                                    }
                                    
                                    do {
                                        try realm.commitWrite();
                                        print("Committing write...");
                                    }
                                    catch (let e)
                                    {
                                        print("Y U NO REALM ? \(e)");
                                    }
                            }
                            // This code will send a notification to every part of the app that listens to it. It’s the de facto notification mechanism in apps, and it’s very effective for events that affect multiple parts of your app. Consider that you’ve just received new data from Foursquare. You may want to update the table view that shows that data, or some other part of your code. A notification is the best way to go about that.
                            NSNotificationCenter.defaultCenter().postNotificationName(API.notifications.venuesUpdated, object: nil, userInfo: nil);
                        }
                    }
            }
            // The Das Quadrat library sends a message to Foursquare, waits for it to come back, and then invokes the closure you wrote to process the data.
            searchTask.start()
        }
    }
}


// Extend the base class CLLocation with an extra method parameters(). Every time a CLLocation instance is used in your code, and this extension is loaded, you can call the method parameters on the instance, even when it’s not part of the original MapKit code.
extension CLLocation {
    func parameters() -> Parameters {
        let ll      = "\(self.coordinate.latitude),\(self.coordinate.longitude)"
        let llAcc   = "\(self.horizontalAccuracy)"
        let alt     = "\(self.altitude)"
        let altAcc  = "\(self.verticalAccuracy)"
        let parameters = [
            Parameter.ll:ll,
            Parameter.llAcc:llAcc,
            Parameter.alt:alt,
            Parameter.altAcc:altAcc
        ]
        return parameters
    }
}
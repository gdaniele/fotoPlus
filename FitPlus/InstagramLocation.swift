//
//  InstagramLocation.swift
//  FitPlus
//
//  Created by Giancarlo Daniele on 9/4/14.
//  Copyright (c) 2014 Giancarlo Daniele. All rights reserved.
//

import UIKit
import CoreLocation

class InstagramLocation: NSObject {
    var name : String!
    var location : CLLocation!
    var lat : CLLocationDegrees!
    var lng : CLLocationDegrees!
    var id : Int!
    
    var recentPhotos : [InstagramPhoto]? // stores ten most recent photos at location
    
    init(name: String, location : CLLocation, lat : CLLocationDegrees?, lng : CLLocationDegrees?, id : Int) {
        self.name = name
        self.location = location
        self.id = id
        
        if lat == nil || lng == nil {
            self.lat = location.coordinate.latitude
            self.lng = location.coordinate.longitude
            println("WARN: Manually set lat/lng")
        } else {
            self.lat = lat
            self.lng = lng
        }
    }
    
    func downloadAndSaveRecentPhotos(success: () -> (), failure: () -> ()) {
        InstagramAPI.requestRecentPhotosFromLocation(String(self.id), success: { (json) -> () in
            println("DEBUG: got photos for location id: \(self.id) \n da photos: \(json)")
            //save the photos in the background
            var backgroundQueue = NSOperationQueue()
            backgroundQueue.addOperationWithBlock({ () -> Void in
                self.parseAndSavePhotos(json, success, failure)
            })
        }) { () -> () in
            //failure! 
            failure()
        }
    }
    
    // Takes Instagram Media response as params and creates instagramPhoto objects
    func parseAndSavePhotos(json : NSDictionary, success : () -> (), failure : () -> ()) {
        for photo in json["data"] as NSArray {
            var photo : InstagramPhoto = InstagramPhoto(fromDictionary: JSONValue(photo))
            println("got one")
        }
    }
}
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
    
    var recentPhotos : [Int]? // stores ten most recent photos at location
    
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
}
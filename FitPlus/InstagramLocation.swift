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
    var instagramId : Int!
    
    init(name: String, location : CLLocation, lat : CLLocationDegrees?, lng : CLLocationDegrees?, instagramId : Int) {
        self.name = name
        self.location = location
        self.instagramId = instagramId
        
        if lat == nil || lng == nil {
            self.lat = location.coordinate.latitude
            self.lng = location.coordinate.longitude
            println("WARN: Manually set lat/lng")
        }
    }
}
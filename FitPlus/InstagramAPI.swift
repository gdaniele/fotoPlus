//
//  InstagramAPI.swift
//  FitPlus
//
//  Created by Giancarlo Daniele on 9/5/14.
//  Copyright (c) 2014 Giancarlo Daniele. All rights reserved.
//

import UIKit
import CoreLocation

class InstagramAPI: NSObject {
    class var sharedInstance :InstagramAPI {
        struct Singleton {
            static let instance = InstagramAPI()
        }
        return Singleton.instance
    }
    var token : String!
    var savedLocation : CLLocation!
    var defaultLocation : CLLocation = CLLocation(latitude: 41.882584, longitude: -87.623190)
    var nearbyInstagramLocations : NSMutableArray = NSMutableArray()

    override func observeValueForKeyPath(keyPath: String!, ofObject object: AnyObject!, change: [NSObject : AnyObject]!, context: UnsafeMutablePointer<Void>) {
        println("keyPath \(keyPath) changed: \(change[NSKeyValueChangeNewKey])")
        if keyPath == "bestEffortAtLocation" {
            InstagramAPI.sharedInstance.savedLocation = change[NSKeyValueChangeNewKey] as? CLLocation
        }
        if keyPath == "accessToken" {
            InstagramAPI.sharedInstance.token = change[NSKeyValueChangeNewKey] as? NSString
        }
        if InstagramAPI.sharedInstance.savedLocation != nil && InstagramAPI.sharedInstance.token != nil {
            InstagramAPI.requestNearbyInstagramLocations(InstagramAPI.sharedInstance.savedLocation, success: { () -> () in
                NSNotificationCenter.defaultCenter().postNotificationName("loadedInstagramLocations", object: self)
            }, failure: { () -> () in
                InstagramAPI.sharedInstance.savedLocation = self.defaultLocation // KVO allows for retry with default location
            })
        }
    }
    
//    //    MARK: Networking
    //gets nearbyLocations from instagram. returns success once they are successfully saved
    class func requestNearbyInstagramLocations(location : CLLocation, success: () -> (), failure: () -> ()) {
        var urlString : String! = "\(InstagramConstants().KAPI_URL_CONSTANT)search?lat=\(location.coordinate.latitude as Double)&lng=\(location.coordinate.longitude as Double)&access_token=\(InstagramAPI.sharedInstance.token)"
        var url : NSURL = NSURL(string: urlString)
        InstagramAPI.sharedInstance.requestWithCallback(url, success: { (json) -> () in
            var otherNearbyLocations : NSMutableArray = json.valueForKey("data")?.mutableCopy() as NSMutableArray
            var backgroundQueue = NSOperationQueue()
            backgroundQueue.addOperationWithBlock() {
                InstagramAPI.sharedInstance.loadNearbyLocations(otherNearbyLocations, success: { () -> () in
                    success()
                })
            }
        }) { () -> () in
            // request failed
            failure()
        }
    }
    
    class func requestRecentPhotosFromLocation(locationId : String, success: (NSDictionary) -> (), failure: () -> ()) {
        var urlString : String! = "\(InstagramConstants().KAPI_URL_CONSTANT)/\(locationId)/media/recent?&access_token=\(InstagramAPI.sharedInstance.token)"
        var url : NSURL = NSURL(string: urlString)
        InstagramAPI.sharedInstance.requestWithCallback(url, success: { (json) -> () in
            //
            success(json)
        }) { () -> () in
            // request failed
            failure()
        }
    }
    
    func requestWithCallback(url : NSURL, success: (NSDictionary) -> (), failure: () -> ()) {
        var session : NSURLSession = NSURLSession.sharedSession()
        var error : NSError?
        session.dataTaskWithURL(url, completionHandler: {(data: NSData!, response: NSURLResponse!, error: NSError!) in
            if (error != nil) {
                println("ERROR: \(error)")
                failure()
            } else {
                var httpResponse : NSHTTPURLResponse = response as NSHTTPURLResponse
                if httpResponse.statusCode == 200 {
                    // this has to be done in ObjC Foundation!
                    var json : NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.convertFromNilLiteral(), error: nil) as NSDictionary
                    success(json)
                } else {
                    println("ERROR: HTTP Response: \(httpResponse)")
                    // TODO: Reachability request here to make sure server is reachable. If callback succeeds, retry
                    
                    // for now, let's just try again. instagram api fails randomly and needs to be retried :(
                    self.requestWithCallback(url, success: success, failure: failure)
                    failure()
                }
            }
        }).resume()
    }
    
    //   MARK: JSON helpers
    func locationObjectFromDict(locationObject : NSDictionary) -> InstagramLocation {
        var name : String!
        if let actualName: AnyObject = locationObject.objectForKey("name") {
            name = actualName as String
        } else {
            name = "\(savedLocation.coordinate.latitude), \(savedLocation.coordinate.longitude)"
        }
        var lat : CLLocationDegrees? = locationObject.objectForKey("latitude")?.doubleValue
        var lng : CLLocationDegrees? = locationObject.objectForKey("longitude")?.doubleValue
        var id : Int! = locationObject.objectForKey("id")?.integerValue
        return InstagramLocation(name: name, location: savedLocation, lat: lat, lng: lng, id: id)
    }
    
    func loadNearbyLocations(locations : NSMutableArray, success: () -> ()) {
        for locationObject in locations {
            var nearbyLocation : InstagramLocation = locationObjectFromDict(locationObject as NSDictionary)
            nearbyInstagramLocations.addObject(nearbyLocation)
        }
        if nearbyInstagramLocations.count > 0 {
            success()
        }
    }
}

//
//  InstagramPhoto.swift
//  FitPlus
//
//  Created by Giancarlo Daniele on 9/4/14.
//  Copyright (c) 2014 Giancarlo Daniele. All rights reserved.
//

import UIKit

class InstagramPhoto: NSObject {
    var caption : String?
    var likeCount : Int?
    var createdAt : NSDate?
    var user : InstagramUser?

    var id : Int!
    
    var linkLowRes : String! = nil
    var linkStandardRes : String! = nil
    var link : String! = nil
    var type : String! = nil
    
    var image : UIImage? = nil
    
    init(fromDictionary photoData : Dictionary<String, AnyObject>) {
        var captionObject: AnyObject? = photoData["caption"]
        println("hiih")
//
//        var likesObject : NSDictionary = photoData.valueForKey("likes") as NSDictionary
//        var likesCount : Int = captionObject.valueForKey("count") as Int
//        
//        var createdAt : NSDate = NSDate(timeIntervalSince1970:(captionObject.valueForKey("count") as NSString).doubleValue)
//        
//        self.caption = captionText
//        self.likeCount = likesCount
//        self.createdAt = createdAt
//        self.user = InstagramUser(fromDictionary: (photoData.objectForKey("user") as NSDictionary))
    }
}
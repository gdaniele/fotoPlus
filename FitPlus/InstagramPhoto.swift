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
    
    init(fromDictionary json : JSONValue) {
        if let typeString = json["type"].string {
            self.type = typeString
        }
        if let linkString = json["link"].string {
            self.link = linkString
        }
        if let likesObject = json["likes"].object {
            if let likesCount = likesObject["count"]?.number {
                self.likeCount = likesCount
            }
            if let likesCountString = likesObject["count"]?.string {
                self.likeCount = likesCountString.toInt()
            }
        }
        if let createdTimeString = json["created_time"].string {
            self.createdAt = NSDate(timeIntervalSince1970:(createdTimeString as NSString).doubleValue)
        } else {
            if let timeNumber = json["created_time"].number {
                self.createdAt = NSDate(timeIntervalSince1970:timeNumber)
            }
        }
        if let captionObject = json["caption"].object {
            if let captionString = captionObject["text"]?.string {
                self.caption = captionString
            }
        }
        if let userObject = json["user"].object {
            self.user = InstagramUser(fromDictionary: userObject)
        }
        if let idString = json["id"].string {
            self.id = idString.toInt()
        }
        if let lowResString = json["images"]["low_resolution"]["url"].string {
            self.linkLowRes = lowResString
        }
        if let standardResString = json["images"]["standard_resolution"]["url"].string {
            self.linkStandardRes = standardResString
        }
    }
}
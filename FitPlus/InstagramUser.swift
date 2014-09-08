//
//  InstagramUser.swift
//  FitPlus
//
//  Created by Giancarlo Daniele on 9/4/14.
//  Copyright (c) 2014 Giancarlo Daniele. All rights reserved.
//

import UIKit

class InstagramUser: NSObject {
    var username : String! = nil
    var full_name : String?
    var id : Int?
    var bio : String?
    var profilePicLink : String?
    var website : String?
    
    var profilePic : UIImage?

    init(fromDictionary data : Dictionary<String, JSONValue>) {
        if let bio = data["bio"]?.string {
            self.bio = bio
        }
        if let fullName = data["full_name"]?.string {
            self.full_name = fullName
        }
        if let id = data["id"]?.number {
            self.id = id
        }
        if let id = data["id"]?.string {
            self.id = id.toInt()
        }
        if let bio = data["bio"]?.string {
            self.bio = bio
        }
        if let website = data["website"]?.string {
            self.website = website
        }
        if let profilePic = data["profile_picture"]?.string {
            self.profilePicLink = profilePic
        }
        if let username = data["username"]?.string {
            self.username = username
        }
    }
}

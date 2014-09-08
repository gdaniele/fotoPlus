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

    init(fromDictionary data : Dictionary<String, AnyObject>) {
//        self.bio = data.objectForKey("bio") as? String
//        self.full_name = data.objectForKey("full_name") as? String
//        self.id = data.objectForKey("id") as? Int
//        self.profilePicLink = data.objectForKey("profile_picture") as? String
//        self.website = data.objectForKey("website") as? String
    }
}

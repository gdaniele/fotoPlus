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
    
    init(username: String, userId : Int, full_name : String, id : Int) {
        self.id = userId
        self.username = username
        self.full_name = full_name
    }
}

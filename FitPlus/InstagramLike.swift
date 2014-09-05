//
//  InstagramLike.swift
//  FitPlus
//
//  Created by Giancarlo Daniele on 9/4/14.
//  Copyright (c) 2014 Giancarlo Daniele. All rights reserved.
//

import UIKit

class InstagramLike: NSObject {
    var username : String! = nil
    var userId : Int! = nil
    var photoId : Int! = nil
    var id : Int! = nil

    init(username: String, userId : Int, imageId : Int, id : Int, photoId : Int) {
        self.userId = userId
        self.username = username
        self.photoId = photoId
        self.id = id
    }
}
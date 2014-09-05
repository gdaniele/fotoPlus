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
    var likes : [Int]?
    var link : String! = nil
    var userId : Int?
    var id : Int!
    
    init(caption: String, likes : [Int], id : Int) {
        self.likes = likes
        self.caption = caption
        self.id = id
    }
}
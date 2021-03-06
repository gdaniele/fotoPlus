//
//  InstagramConstants.swift
//  FotoPlus
//
//  Created by Giancarlo Daniele on 9/5/14.
//  Copyright (c) 2014 Giancarlo Daniele. All rights reserved.
//

import UIKit

class InstagramConstants: NSObject {
    let KAUTH_URL_CONSTANT : String! = "https://api.instagram.com/oauth/authorize/"
    let KAPI_URL_CONSTANT : String! = "https://api.instagram.com/v1/locations/"
    let KAPI_URL_MEDIA_CONSTANT : String! = "https://api.instagram.com/v1/media/"
    let KCLIENT_ID_CONSTANT : String! = "5d93c4bc1c594d749acb20fe766c5059"
    let KCLIENT_SERCRET_CONSTANT : String! = "d12c3631a25e4ffaa824737088a43439"
    let KREDIRECT_URI_CONSTANT : String! = "https://0.0.0.0"
    var cellHeaderHeight : Float = 25
    var cellFooterHeight : Float = 25
    var cellWidth = Float(UIScreen.mainScreen().bounds.size.width) - 20.0
    var cellHeight = Float(UIScreen.mainScreen().bounds.size.width) - 20.0 + 50
}
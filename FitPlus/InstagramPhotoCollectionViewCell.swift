//
//  InstagramPhotoCollectionViewCell.swift
//  FitPlus
//
//  Created by Giancarlo Daniele on 9/7/14.
//  Copyright (c) 2014 Giancarlo Daniele. All rights reserved.
//

import UIKit

class InstagramPhotoCollectionViewCell: UICollectionViewCell {
    var mediaID : String?
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var timeAgoLabel: UILabel!
    @IBOutlet weak var likesCountLabel: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    @IBAction func likeButtonPressed(sender: AnyObject) {
        if let id : String = self.mediaID {
            InstagramAPI.likeRequestForPhoto(id, success: { (json) -> () in
                var data = JSONValue(json)
                println("DEBUG: Photo was liked successfully")
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    self.likeButton.setTitle("You liked this", forState: UIControlState.Normal)
                })
            }) { () -> () in
                    //
            }
        }
    }
}
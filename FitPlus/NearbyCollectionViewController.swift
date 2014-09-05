//
//  NearbyCollectionViewController.swift
//  FitPlus
//
//  Created by Giancarlo Daniele on 9/3/14.
//  Copyright (c) 2014 Giancarlo Daniele. All rights reserved.
//

import UIKit
import CoreLocation

let reuseIdentifier = "Cell"

class NearbyCollectionViewController: UICollectionViewController, UIWebViewDelegate, CLLocationManagerDelegate {
    @IBOutlet var photoCollectionView: UICollectionView!
    var webView : UIWebView! = nil
    
    var KAUTH_URL_CONSTANT : String! = "https://api.instagram.com/oauth/authorize/"
    var KAPI_URL_CONSTANT : String! = "https://api.instagram.com/v1/locations/"
    var KCLIENT_ID_CONSTANT : String! = "5d93c4bc1c594d749acb20fe766c5059"
    var KCLIENT_SERCRET_CONSTANT : String! = "d12c3631a25e4ffaa824737088a43439"
    var KREDIRECT_URI_CONSTANT : String! = "https://0.0.0.0"
    var KDEFAULT_LOCATION_CHICAGO_CONSTANT : String! = "41.882584,-87.623190"
    
    let activityIndicator : UIActivityIndicatorView! = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    
    var locationMeasurements : [CLLocation]! = []
    var bestEffortAtLocation : CLLocation?
    var manager : CLLocationManager! = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView?.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        getLocation()
        refreshNearbyPhotos()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 0
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //#warning Incomplete method implementation -- Return the number of items in the section
        return 0
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as UICollectionViewCell
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    func collectionView(collectionView: UICollectionView!, shouldHighlightItemAtIndexPath indexPath: NSIndexPath!) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    func collectionView(collectionView: UICollectionView!, shouldSelectItemAtIndexPath indexPath: NSIndexPath!) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    func collectionView(collectionView: UICollectionView!, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath!) -> Bool {
        return false
    }

    func collectionView(collectionView: UICollectionView!, canPerformAction action: String!, forItemAtIndexPath indexPath: NSIndexPath!, withSender sender: AnyObject!) -> Bool {
        return false
    }

    func collectionView(collectionView: UICollectionView!, performAction action: String!, forItemAtIndexPath indexPath: NSIndexPath!, withSender sender: AnyObject!) {
    
    }
    */
    
//    MARK: Networking
    func authorizeInstagram() {
        // authenticate
        var fullURL : String! = "\(KAUTH_URL_CONSTANT)?client_id=\(KCLIENT_ID_CONSTANT)&redirect_uri=\(KREDIRECT_URI_CONSTANT)&response_type=token"
        var url : NSURL = NSURL(string: fullURL)
        var requestObject = NSURLRequest(URL: url)
        var screenBounds = UIScreen.mainScreen().bounds
        webView = UIWebView(frame: CGRect(x: 0, y: 0, width: screenBounds.size.width, height: screenBounds.size.height))
        webView.delegate = self
        webView.loadRequest(requestObject)
        webView.scalesPageToFit = true
        webView.contentMode = UIViewContentMode.ScaleAspectFit
        self.view.addSubview(webView)
    }
    
    func refreshNearbyPhotos() {
        var accessToken : String? = NSUserDefaults.standardUserDefaults().valueForKey("KACCESS_TOKEN_CONSTANT") as String?
        if accessToken != nil {
            
        } else {
            authorizeInstagram()
        }
    }

//    MARK: UIWebViewDelegate
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        var urlString : String! = request.URL.absoluteString
        var urlParts : Array = urlString.componentsSeparatedByString("\(KREDIRECT_URI_CONSTANT)/")
        if urlParts.count > 1 {
            urlString = urlParts[1]
            var accessToken : Range? = urlString.rangeOfString("#access_token=", options: nil, range: nil, locale: nil)
            if accessToken != nil {
                var strAccessToken : String = urlString.substringFromIndex(accessToken!.endIndex)
                let KACCESS_TOKEN_CONSTANT : String = strAccessToken
                NSUserDefaults.standardUserDefaults().setValue(strAccessToken, forKeyPath: "KACCESS_TOKEN_CONSTANT")
                NSUserDefaults.standardUserDefaults().synchronize()
                println("Saved instagram access token to defaults")
                webView.removeFromSuperview()
                activityIndicator.removeFromSuperview()
            }
            return false
        }
        return true
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        //put activity indicator on screen
        activityIndicator.center = self.view.center
        activityIndicator.startAnimating()
        self.view.addSubview(activityIndicator)
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        //remove activity indicator on screen
        activityIndicator.removeFromSuperview()
    }
    
//    MARK: Core Location
    func getLocation() {
        if CLLocationManager.locationServicesEnabled() && CLLocationManager.authorizationStatus() != CLAuthorizationStatus.Denied {
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            manager.distanceFilter = kCLDistanceFilterNone
            manager.requestWhenInUseAuthorization()
            manager.startUpdatingLocation()
        } else {
            println("\(CLLocationManager.authorizationStatus().toRaw())")
        }
    }
    
    // CLLocation Delegate Methods
    func locationManager(manager: CLLocationManager!, didUpdateToLocation newLocation: CLLocation!, fromLocation oldLocation: CLLocation!) {
        locationMeasurements.append(newLocation)
        var locationAge : NSTimeInterval = newLocation.timestamp.timeIntervalSinceNow
        if locationAge > 5.0 { //make sure location is fresh
            return
        }
        if newLocation.horizontalAccuracy < 0 { //make sure horizontal accuracy doesn't indicate that something went wrong
            return
        }
        if bestEffortAtLocation == nil || bestEffortAtLocation?.horizontalAccuracy > newLocation.horizontalAccuracy {
            bestEffortAtLocation = newLocation
            if newLocation.horizontalAccuracy <= manager.desiredAccuracy {
                manager.stopUpdatingLocation()
            }
        }
//        TODO: Update the collectionView here with maybe a new network call
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println("Location Manager failed")
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        println("\(status.toRaw())")
    }
}

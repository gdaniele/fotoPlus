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
    
    var api : InstagramAPI = InstagramAPI.sharedInstance
    
    dynamic var accessToken : String!

    let activityIndicator : UIActivityIndicatorView! = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    var webView : UIWebView! = nil
    
    var manager : CLLocationManager! = CLLocationManager()
    var locationMeasurements : [CLLocation]! = [] //array of CLLocations.. some will be stale
    var defaultLocation : CLLocation?
    dynamic var bestEffortAtLocation : CLLocation!
    
    var currentLocation : InstagramLocation! = nil
    var recentPhotos : [InstagramPhoto]! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView?.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
        
        // add KVO
        addobservers()
        
        // set default location to the Windy City :)
        defaultLocation = CLLocation(latitude: 41.882584, longitude: -87.623190)
    }
    
    override func viewDidDisappear(animated: Bool) {
        removeObservers()
    }
    
    override func viewWillAppear(animated: Bool) {
        getLocation()
        refreshAccessToken()
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
    
//    MARK: Utilities
    func addobservers() {
        self.addObserver(api, forKeyPath: "accessToken", options: NSKeyValueObservingOptions.New, context: nil)
        self.addObserver(api, forKeyPath: "bestEffortAtLocation", options: NSKeyValueObservingOptions.New, context: nil)
        self.addObserver(self, forKeyPath: "currentLocation", options: NSKeyValueObservingOptions.New, context: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "instagramLocationsLoaded:", name: "loadedInstagramLocations", object: nil)

    }
    
    func removeObservers() {
        self.removeObserver(api, forKeyPath: "accessToken")
        self.removeObserver(api, forKeyPath: "bestEffortAtLocation")
        self.removeObserver(self, forKeyPath: "currentLocation")
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "loadedInstagramLocations", object: nil)

    }
    
//    Gets Instagram access_token from UserDefaults or presents Instagram login screen to user
    func refreshAccessToken() {
        // Once the access token is set, the callback will download photos
        var accessToken : String? = NSUserDefaults.standardUserDefaults().valueForKey("KACCESS_TOKEN_CONSTANT") as String?
        if accessToken != nil {
            self.accessToken = accessToken
        } else {
            authorizeInstagram()
        }
    }
    
//    Presents a UIWebView to allow user to authenticate into their Instagram account
    func authorizeInstagram() {
        // authenticate
        var fullURL : String! = "\(InstagramConstants().KAUTH_URL_CONSTANT)?client_id=\(InstagramConstants().KCLIENT_ID_CONSTANT)&redirect_uri=\(InstagramConstants().KREDIRECT_URI_CONSTANT)&response_type=token"
        var url : NSURL = NSURL(string: fullURL)
        var requestObject = NSURLRequest(URL: url)
        var screenBounds = UIScreen.mainScreen().bounds
        webView = UIWebView(frame: CGRect(x: 0, y: 20, width: screenBounds.size.width, height: screenBounds.size.height - 20))
        webView.delegate = self
        webView.loadRequest(requestObject)
        webView.scalesPageToFit = true
        webView.contentMode = UIViewContentMode.ScaleAspectFit
        self.view.addSubview(webView)
    }
    
    func resetLocationLookup() {
        UIAlertView(title: "Instagram error", message: "Can't find this location on Instagram. Defaulting to Chicago", delegate: self, cancelButtonTitle: "OK").show()
        self.bestEffortAtLocation = defaultLocation
    }
    
//    Incoming NSNotification that informs the view that the Instagram API found locations with our given CLLocation
    func instagramLocationsLoaded(notification: NSNotification){
        println("DEBUG: Downloaded InstagramLocation objects")
        loadInstagramLocationToView(api.nearbyInstagramLocations.firstObject as InstagramLocation)
    }
    
//    Loads the given Instagram Location to the view
    func loadInstagramLocationToView(location : InstagramLocation) {
        // Set the current location
        
        // Remove existing photos from UICollectionView
        
        
        // Dispatch a thread to download & parse metadata for photos at given location
        location.downloadAndSaveRecentPhotos({ () -> () in
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                // On the main queue, reload the UICollectionView
                
            })
        }, failure: { () -> () in
            
        })
    }
    
//    MARK: UIWebViewDelegate
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        var urlString : String! = request.URL.absoluteString
        var urlParts : Array = urlString.componentsSeparatedByString("\(InstagramConstants().KREDIRECT_URI_CONSTANT)/")
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
                self.accessToken = strAccessToken
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
            bestEffortAtLocation = defaultLocation
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
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        if (error != nil) {
            println("Location Manager failed with error: \(error.localizedDescription)")
            bestEffortAtLocation = defaultLocation
        }
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.Denied {
            bestEffortAtLocation = defaultLocation
        }
        println("Location Authorization changed to: \(status.toRaw())")
    }
}

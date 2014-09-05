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
    var defaultLocation : CLLocation! = CLLocation(latitude: 41.882584, longitude: -87.623190)
    
    let activityIndicator : UIActivityIndicatorView! = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    
    var locationMeasurements : [CLLocation]! = [] //array of CLLocations.. some will be stale
    var manager : CLLocationManager! = CLLocationManager()
    var otherLocations : [InstagramLocation]?
    
    dynamic var currentLocation : InstagramLocation? { //once we have a location from device, we resolve to an instagram locationId
        didSet {
            
        }
    }
    
    dynamic var bestEffortAtLocation : CLLocation! {
        didSet {
            if bestEffortAtLocation != nil && accessToken != nil{
                loadRequestForNearbyPhotos()
            }
        }
    }
    dynamic var accessToken : String! {
        didSet {
            if accessToken != nil && bestEffortAtLocation != nil {
                loadRequestForNearbyPhotos()
            }
        }
    }
    
    override func observeValueForKeyPath(keyPath: String!,
        ofObject object: AnyObject!,
        change: [NSObject : AnyObject]!,
        context: UnsafeMutablePointer<()>) {
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView?.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
        
        // add KVO
        addobservers()
    }
    
    override func viewDidDisappear(animated: Bool) {
        removeObservers()
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
    
//    MARK: Utilities
    func addobservers() {
        self.addObserver(self, forKeyPath: "accessToken", options: NSKeyValueObservingOptions.New, context: nil)
        self.addObserver(self, forKeyPath: "bestEffortAtLocation", options: NSKeyValueObservingOptions.New, context: nil)
        self.addObserver(self, forKeyPath: "currentLocation", options: NSKeyValueObservingOptions.New, context: nil)
    }
    
    func removeObservers() {
        self.removeObserver(self, forKeyPath: "accessToken")
        self.removeObserver(self, forKeyPath: "bestEffortAtLocation")
        self.removeObserver(self, forKeyPath: "currentLocation")
    }
    
    func locationObjectFromDict(locationObject : NSDictionary) -> InstagramLocation {
        var name : String!
        if let actualName = locationObject.objectForKey("name") {
            name = actualName as String
        } else {
            name = "\(self.bestEffortAtLocation.coordinate.latitude), \(self.bestEffortAtLocation.coordinate.longitude)"
        }
        var lat : CLLocationDegrees? = locationObject.objectForKey("latitude")?.doubleValue
        var lng : CLLocationDegrees? = locationObject.objectForKey("longitude")?.doubleValue
        var id : Int! = locationObject.objectForKey("id")?.integerValue
        return InstagramLocation(name: name, location: defaultLocation, lat: lat, lng: lng, id: id)
    }
    
    func loadNearbyLocations(locations : NSMutableArray) {
        for locationObject in locations {
            var nearbyLocation : InstagramLocation = locationObjectFromDict(locationObject as NSDictionary)
            otherLocations?.append(nearbyLocation)
        }
    }
    
//    MARK: Networking
    func authorizeInstagram() {
        // authenticate
        var fullURL : String! = "\(KAUTH_URL_CONSTANT)?client_id=\(KCLIENT_ID_CONSTANT)&redirect_uri=\(KREDIRECT_URI_CONSTANT)&response_type=token"
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
    
    func refreshNearbyPhotos() {
        // Once the access token is set, the callback will download photos
        var accessToken : String? = NSUserDefaults.standardUserDefaults().valueForKey("KACCESS_TOKEN_CONSTANT") as String?
        if accessToken != nil {
            self.accessToken = accessToken
        } else {
            authorizeInstagram()
        }
    }
    
    func getInstagramLocationId() {
        var session : NSURLSession = NSURLSession.sharedSession()
        var urlString : String! = "\(KAPI_URL_CONSTANT)search?lat=\(bestEffortAtLocation.coordinate.latitude as Double)&lng=\(bestEffortAtLocation.coordinate.longitude as Double)&access_token=\(accessToken)"
        var url : NSURL = NSURL(string: urlString)
        var error : NSError?
        session.dataTaskWithURL(url, completionHandler: {(data: NSData!, response: NSURLResponse!, error: NSError!) in
            if (error != nil) {
                println("ERROR: \(error)")
            } else {
                var httpResponse : NSHTTPURLResponse? = response as NSHTTPURLResponse
                if httpResponse?.statusCode == 200 {
                    // this has to be done in ObjC Foundation!
                    var json : NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.convertFromNilLiteral(), error: nil) as NSDictionary
                    var otherNearbyLocations : NSMutableArray = json.valueForKey("data")?.mutableCopy() as NSMutableArray
                    var locationObject : NSDictionary? = otherNearbyLocations.firstObject as NSDictionary
                    if otherNearbyLocations.count > 1 {
                        otherNearbyLocations.removeObjectAtIndex(0)
                    }
                    if locationObject != nil {
                        var location : InstagramLocation = self.locationObjectFromDict(locationObject!)
                        self.currentLocation = location
                        println("DEBUG: Successfully found instagram location id \(location.id)")
                        
                        var backgroundQueue = NSOperationQueue()
                        backgroundQueue.addOperationWithBlock() {
                            self.loadNearbyLocations(otherNearbyLocations)
                        }
                    } else {
                        println("ERROR: No location object from instagram")
                        self.resetLocationLookup()
                    }
                } else {
                    println("ERROR: HTTP Response: \(httpResponse)")
                    self.resetLocationLookup()
                }
            }
        }).resume()
    }
    
    func resetLocationLookup() {
        UIAlertView(title: "Instagram error", message: "Can't find this location on Instagram. Defaulting to Chicago", delegate: self, cancelButtonTitle: "OK").show()
        self.bestEffortAtLocation = self.defaultLocation
    }
    
    func loadRequestForNearbyPhotos() {
        println("DEBUG: Successfully authenticated")
        if bestEffortAtLocation == defaultLocation {
            println("DEBUG :Using default location")
        } else {
            println("DEBUG: Using device location")
        }
        getInstagramLocationId()
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
//        TODO: Update the collectionView here with maybe a new network call
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

//
//  NearbyCollectionViewController.swift
//  FitPlus
//
//  Created by Giancarlo Daniele on 9/3/14.
//  Copyright (c) 2014 Giancarlo Daniele. All rights reserved.
//

import UIKit
import CoreLocation

let reuseIdentifier = "photoCell"

class NearbyCollectionViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, CLLocationManagerDelegate, UIWebViewDelegate, UINavigationBarDelegate {
    var collectionView: UICollectionView?
    let kImageViewTag : Int = 11 //the imageView for the collectionViewCell is tagged with 11 in IB
    let kHeaderViewTag : Int = 33 //the header for the collectionViewCell is tagged with 33 in IB
    let kFooterViewTag : Int = 22 //the footer for the collectionViewCell is tagged with 22 in IB
    let kNavbarTag : Int = 87
    var api : InstagramAPI = InstagramAPI.sharedInstance //shared instance of our api helper. it also manages the access_token from instagram
    dynamic var accessToken : String! //dynamic KVO variable that sets access_token from UIWebView presented in this controller
    let activityIndicator : UIActivityIndicatorView! = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray) //for loading UIWebView
    var webView : UIWebView! = nil //WebView for Instagram login
    var manager : CLLocationManager! = CLLocationManager()
    var locationMeasurements : [CLLocation]! = [] //array of CLLocations.. some will be stale
    var defaultLocation : CLLocation = InstagramAPI.sharedInstance.defaultLocation // Fallback CLLocation for app for when GPS is not available
    dynamic var bestEffortAtLocation : CLLocation! // Keeps track of most accurate GPS reading
    var locationOnDisplay : InstagramLocation? = nil // Current Location ID (Instagram) of recent photo feed currently on screen
    var indexOfLocation : Int! = 0 // We have multiple Instagram locations for a plae. The index is which one is loaded
    var stateStatusView : UIView! // UIView overlay that communicates state messages to user
    var navBar : UINavigationBar!
    var imageDownloadsInProgress = Dictionary<NSIndexPath, PhotoDownloader>() // Mutable data structure of images currently being downloaded. We are lazy loading!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 20, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: CGFloat(InstagramConstants().cellWidth), height: CGFloat(InstagramConstants().cellHeight))
        //add the image view for photo display
        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionView!.dataSource = self
        collectionView!.delegate = self
        collectionView!.registerNib(UINib(nibName: "InstagramPhotoCollectionViewCell", bundle: NSBundle.mainBundle()), forCellWithReuseIdentifier: reuseIdentifier)
        collectionView!.backgroundColor = UIColor.whiteColor()
        self.view.addSubview(collectionView!)
        
        // add KVO
        addobservers()
        
        //set up uinavigation bar
        navBar = UINavigationBar()
        navBar.frame = CGRectMake(0, 20, self.view.frame.size.width, 44)
        navBar.delegate = self
        
        //navbar titles and location swapping
        var item = UINavigationItem(title: "Loading Nearby Photos..")
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            item.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Camera, target: self, action: "loadCamera")
        }
        navBar.pushNavigationItem(item, animated: true)
        var navSingleTap = UITapGestureRecognizer(target: self, action: "navSingleTap")
        navSingleTap.numberOfTapsRequired = 1
        (navBar.subviews[1] as UIView).userInteractionEnabled = true
        (navBar.subviews[1] as UIView).addGestureRecognizer(navSingleTap)
        navBar.tag = kNavbarTag
        
        self.view.addSubview(navBar)
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
        for (key, downloader) in imageDownloadsInProgress {
            downloader.cancelDownload({
                println("DEBUG: Cancelled download successfully")
            })
        }
        self.imageDownloadsInProgress.removeAll(keepCapacity: false)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.collectionView?.contentInset = UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0)
        self.collectionView?.reloadData()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
    
    func loadCamera() {
        var story = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        var snapController = story.instantiateViewControllerWithIdentifier("snapController") as CameraViewController
        snapController.modalPresentationStyle = UIModalPresentationStyle.FullScreen
        self.presentViewController(snapController as UIViewController, animated: true, completion: nil)
    }
    
    func navSingleTap() {
        if api.nearbyInstagramLocations.count > 0 {
            indexOfLocation = (indexOfLocation + 1) % api.nearbyInstagramLocations.count
            loadInstagramLocationToView(api.nearbyInstagramLocations[indexOfLocation] as InstagramLocation)
        }
    }
    
    // MARK: UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let location = self.locationOnDisplay as InstagramLocation? {
            return location.recentPhotos.count
        }
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var screenSize = UIScreen.mainScreen().bounds.size
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as InstagramPhotoCollectionViewCell
        
//        Load the photo for this cell
        if let location = self.locationOnDisplay {
            if location.recentPhotos.count >= indexPath.row {
                var photo : InstagramPhoto = location.recentPhotos[indexPath.row]
                if let likesCount : Int = photo.likeCount {
                    cell.likesCountLabel.text = String(likesCount) + " likes"
                } else {
                    cell.likesCountLabel.text = ""
                }
                if let id : String = photo.id {
                    cell.mediaID = id
                } else {
                    println("ERROR: cell without mediaID")
                }
                if let username : String = photo.user?.username {
                    cell.usernameLabel.text = username
                } else {
                    cell.usernameLabel.text = ""
                }
                if let createdAt : NSDate = photo.createdAt {
                    var formatter : NSDateFormatter = NSDateFormatter()
                    formatter.dateFormat = "MM/dd/yyyy"
                    cell.timeAgoLabel.text = formatter.stringFromDate(createdAt)
                } else {
                    cell.usernameLabel.text = ""
                }
                if (photo.image == nil) {
                    // Dispatch operation to download the image
                    if self.collectionView?.dragging == false && self.collectionView?.decelerating == false
                    {
                        startPhotoDownload(photo, indexPath: indexPath)
                    }
                    if let imageView = cell.viewWithTag(kImageViewTag) as? UIImageView {
                        imageView.image = UIImage(named: "placeholder")
                    }
                } else {
                    if let imageView = cell.viewWithTag(kImageViewTag) as? UIImageView {
                        imageView.image = photo.image
                    }
                }

            }
        }
        return cell
    }
    
    // Starts PhotoDownload for Photo at index
    func startPhotoDownload(photo : InstagramPhoto, indexPath : NSIndexPath) {
        var downloader = self.imageDownloadsInProgress[indexPath]
        
        if (downloader == nil) {
            downloader = PhotoDownloader()
            downloader?.photo = photo
            self.imageDownloadsInProgress[indexPath] = downloader
            downloader!.completion = {
                if let cell : InstagramPhotoCollectionViewCell = self.collectionView?.cellForItemAtIndexPath(indexPath) as? InstagramPhotoCollectionViewCell {
                    cell.imageView.image = photo.image
                    self.imageDownloadsInProgress.removeValueForKey(indexPath)
                }
            }
            downloader?.startDownload()
        }
    }
    
    // This method is used in case the user scrolled into a set of cells that don't
    //  have their app icons yet.
    func loadImagesForOnscreenRows() {
        if self.locationOnDisplay?.recentPhotos.count > 0  {
            var visiblePaths = self.collectionView!.indexPathsForVisibleItems() as [NSIndexPath]
            for path in visiblePaths {
                if let photo = self.locationOnDisplay?.recentPhotos[path.row] {
                    if (photo.image == nil) {
                        startPhotoDownload(photo, indexPath: path)
                    }
                }
            }
        }
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.loadImagesForOnscreenRows()
        }
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        self.loadImagesForOnscreenRows()
    }
    
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
        var fullURL : String! = "\(InstagramConstants().KAUTH_URL_CONSTANT)?client_id=\(InstagramConstants().KCLIENT_ID_CONSTANT)&redirect_uri=\(InstagramConstants().KREDIRECT_URI_CONSTANT)&scope=likes&response_type=token"
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
    
// A location update failure or authorization failure notifies user that default location will be used to find recent photos
    func relocationOnDisplayLookup() {
        UIAlertView(title: "Instagram error", message: "Can't find this location on Instagram. Defaulting to Sydney", delegate: self, cancelButtonTitle: "OK").show()
        self.bestEffortAtLocation = defaultLocation
    }
    
//    Incoming NSNotification that informs the view that the Instagram API found locations with our given CLLocation
    func instagramLocationsLoaded(notification: NSNotification){
        println("DEBUG: Downloaded InstagramLocation objects")
        loadInstagramLocationToView(api.nearbyInstagramLocations[indexOfLocation] as InstagramLocation)
    }
    
//    Loads the given Instagram Location to the view
    func loadInstagramLocationToView(location : InstagramLocation) {
        // Set the current location
        self.locationOnDisplay = location

        // Dispatch a thread to download & parse metadata for photos at given location
        location.downloadAndSaveRecentPhotos({ () -> () in
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                // On the main queue, reload the UICollectionView
                if self.locationOnDisplay?.recentPhotos.count < 1 {
                    self.navSingleTap()
                } else {
                    self.navBar.topItem?.title = self.locationOnDisplay?.name
                    self.collectionView?.reloadData()
                }
            })
        }, failure: { () -> () in
            
        })
    }
    
//    Toggles stateStatusView
    func toggleStateStatusView(enabled : Bool, text : String?) {
        if enabled{
            var screenBounds = UIScreen.mainScreen().bounds
            stateStatusView = UIView(frame: CGRect(x: 0, y: 20, width: screenBounds.size.width, height: screenBounds.size.height - 20))
            var messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 180, height: 100))
            messageLabel.text = text
            messageLabel.center = stateStatusView.center
            messageLabel.font = UIFont(name: "Helvetica Neue", size: 25)
            messageLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
            messageLabel.numberOfLines = 0
            messageLabel.textAlignment = NSTextAlignment.Center
            messageLabel.sizeToFit()
            messageLabel.textColor = UIColor.darkGrayColor()
            stateStatusView.addSubview(messageLabel)
            self.view.addSubview(stateStatusView)
        } else {
            if self.stateStatusView != nil {
                self.stateStatusView.removeFromSuperview()
                self.stateStatusView = nil
            }
        }
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
    
//    UINavigationBar Delegates
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.TopAttached
    }
    
    func uicolorFromHex(rgbValue:UInt32)->UIColor{
        let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
        let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
        let blue = CGFloat(rgbValue & 0xFF)/256.0
        
        return UIColor(red:red, green:green, blue:blue, alpha:1.0)
    }
}

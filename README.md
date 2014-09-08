# Foto+
Foto+ is an iOS 8 Swift app that shows you nearby Instagram photos and allows you to take photos and save them to your camera role. Foto+ is written entirely in Swift and uses `AVFoundation,` `CoreLocation`, and `UICollectionViews`.

![Gaining Weight](/assets/3lazyLoading.gif?raw=true =400x)


## Get Started
###Setup
There are no special dependencies. Get started as follows:

	git clone git@github.com:gdaniele/fotoPlus.git
	cd fotoPlus
	open FotoPlus.xcodeproj/
	
1. Build Foto+ on an iOS 8 device or in the simulator*
2. Allow Location and camera access when prompted by iOS
2. Log into a valid Instagram account
3. Click the Location Name in the title bar to swap to feeds of other nearby locations


 * Note that for iOS Simulator and devices without camera, `CameraViewController` and associated AVFoundation camera functionality is not supported.

###A Note about XCode
This app was built and tested with XCode 6 Beta 7. For best compatibility, this version of XCode should be used until this project is updated.


## Functional Overview
###Take a photo
![Gaining Weight](/assets/1snapPhotos.PNG?raw=true =400x)

###View photos from the closest Instagram Location
![Gaining Weight](/assets/1takeSnapshot.PNG?raw=true =400x)

###View Other Nearby Locations by Tapping Title
![Gaining Weight](/assets/3changeLocation.gif?raw=true =400x)

## Technical Overview

###LazyLoading with Closures and NSOperation
![Gaining Weight](/assets/1lazyLoading.png?raw=true =400x)

###New iOS 8 Permissions
![Gaining Weight](/assets/1permissions.PNG?raw=true =400x)

## Next Steps
###Swift Housekeeping
Swift is a young languge. Class and static variables are currently not supported. This app will likely need to be updated for the release of iOS 8 and XCode 6.

###Unliking Photos
The `InstagramAPI` class should support unlike requests, but the Instagram API currently does not support unliking photos. Unliking could be supporting in the future using an `NSURLSession` to make a request with an  delete HTTP header method.

###Persistent Data
FotoPlus requests data from Instagram each time a feed is presented to the view. State data is never saved, so a force quit or device restart will delete information from the app. Next steps here would be to use NSCoder or CoreData to persist data efficiently.
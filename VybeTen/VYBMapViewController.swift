//
//  VYBMapViewController.swift
//  VybeTen
//
//  Created by jinsuk on 10/29/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//
import UIKit
import MapKit

@objc class VYBMapViewController: UIViewController, MKMapViewDelegate, VYBPlayerViewControllerDelegate {
  var delegate: AnyObject?
  
  private var _isSimpleMap = false
  private var targetCoordinate: CLLocationCoordinate2D?
  
  @IBOutlet weak var mapView: MKMapView!
  
  @IBAction func dismissButtonPressed(sender: AnyObject) {
    self.presentingViewController?.dismissViewControllerAnimated(false, completion: nil)
  }
  
  var _activeZoneAnnotations: [SimpleAnnotation]!
  var currLocation: MKAnnotation!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if _isSimpleMap {      
      mapView = MKMapView(frame: self.view.frame)
      self.view.addSubview(mapView)
      
      if let coordinate = targetCoordinate? {
        mapView.delegate = self
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(coordinate, span)
        self.mapView.setRegion(region, animated: true)
        
        // this is current location annoation
        let currLocAnnotation = SimpleAnnotation(coordinate: coordinate)
        
        self.mapView.addAnnotation(currLocAnnotation)
      }
      return
    }
    
    self.setUpMapRegion()
    
    MBProgressHUD.showHUDAddedTo(self.mapView, animated: true)
    ZoneStore.sharedInstance.getAllZones { (success) -> Void in
      let zonesOnScreen = ZoneStore.sharedInstance.allZones()
      self.updateZoneAnnoations(zonesOnScreen)
      
      MBProgressHUD.hideAllHUDsForView(self.mapView, animated: true)
    }
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    if _isSimpleMap {
      return
    }
    
    self.refreshZoneAnnoation()
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
#if DEBUG
#else
    if let tracker = GAI.sharedInstance().defaultTracker {
      tracker.set(kGAIScreenName, value: "Map Screen")
      tracker.send(GAIDictionaryBuilder.createScreenView().build())
    }
#endif
  }
  
  func displayLocation(coordinate: CLLocationCoordinate2D) {
    _isSimpleMap = true
    targetCoordinate = coordinate
    
    if let presenterVC = self.delegate as? UIViewController {
      presenterVC.presentViewController(self, animated: true, completion: nil)
    }
  }
  
  private func setUpMapRegion() {
    mapView.delegate = self
    
    PFGeoPoint.geoPointForCurrentLocationInBackground { (geoPoint: PFGeoPoint!, error: NSError!) -> Void in
      var location: CLLocationCoordinate2D
      if error == nil {
        location = CLLocationCoordinate2DMake(geoPoint.latitude, geoPoint.longitude)
      }
      else {
        // Somewhere in montreal
        location = CLLocationCoordinate2DMake(45.503039, -73.570120)
      }
      let span = MKCoordinateSpanMake(0.05, 0.05)
      let region = MKCoordinateRegionMake(location, span)
      self.mapView.setRegion(region, animated: true)
      
      // this is current location annoation
      let currLocAnnotation = SimpleAnnotation(coordinate: location)
      currLocAnnotation.isCurrentLocation = true
      
      self.mapView.addAnnotation(currLocAnnotation)
    }
  }
  
  private func moveMapToRegionAround(location: CLLocationCoordinate2D) {
    let span = MKCoordinateSpanMake(0.05, 0.05)
    let region = MKCoordinateRegionMake(location, span)
    mapView.setRegion(region, animated: false)
  }
  
  
  private func updateZoneAnnoations(newZones: [Zone]) {
    self.mapView.removeAnnotations(_activeZoneAnnotations)
    _activeZoneAnnotations = []
    
    for aZone in newZones {
      let simpleAnnotation = SimpleAnnotation(zone: aZone)
      _activeZoneAnnotations.append(simpleAnnotation)
      self.mapView.addAnnotation(simpleAnnotation)
    }
  }
  
  
  func refreshZoneAnnoation() {
    let zonesOnScreen = ZoneStore.sharedInstance.allZones()
    self.updateZoneAnnoations(zonesOnScreen)
  }
  
  func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
    let simpleAnnotation = annotation as SimpleAnnotation
    if simpleAnnotation.isCurrentLocation {
      let pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "currentLocatinPin")
      pin.pinColor = MKPinAnnotationColor.Green
      
      return pin
    }
    
    var pin = mapView.dequeueReusableAnnotationViewWithIdentifier("zonePin") as MKAnnotationView!
    
    if pin == nil {
      pin = MKAnnotationView(annotation: annotation, reuseIdentifier: "zonePin")
    }
    
    if _isSimpleMap {
      pin.image = UIImage(named: "Pin_Watched")
      
      return pin
    }
    
    pin.canShowCallout = true
    
    let accessoryView = UIButton(frame: CGRectMake(0, 0, 41, 41))
    accessoryView.setImage(UIImage(named: "Map_Pin_Play_Blue"), forState: UIControlState.Normal)
    pin.rightCalloutAccessoryView = accessoryView
    
    if simpleAnnotation.unwatched {
      pin.image = UIImage(named: "Pin_Unwatched")
    }
    else {
      pin.image = UIImage(named: "Pin_Watched")
    }
    
    return pin
  }
  
  func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
    let zone = view.annotation as SimpleAnnotation
    
    var playerVC = VYBPlayerViewController()
    playerVC.delegate = self
    MBProgressHUD.showHUDAddedTo(self.view, animated: true)
    if zone.isActive {
      playerVC.playFreshVybesFromZone(zone.zoneID)
    } else {
      var query = PFQuery(className: kVYBVybeClassKey)
      query.whereKey(kVYBVybeZoneIDKey, equalTo: zone.zoneID)
      let startTime = ConfigManager.sharedInstance.startTimeForMap()
      query.whereKey(kVYBVybeTimestampKey, greaterThanOrEqualTo: startTime)
      query.orderByAscending(kVYBVybeTimestampKey)
      query.includeKey(kVYBVybeUserKey)

      query.findObjectsInBackgroundWithBlock({ (result: [AnyObject]!, error: NSError!) -> Void in
        if error == nil {
          playerVC.playStream(result)
        } else {
          MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
        }
      })
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
  override func shouldAutorotate() -> Bool {
    return true
  }
  
  override func supportedInterfaceOrientations() -> Int {
    return Int(UIInterfaceOrientationMask.Portrait.rawValue)
  }
  
  func playerViewController(playerVC: VYBPlayerViewController!, didFinishSetup ready: Bool) {
    MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
    if ready {
      self.presentViewController(playerVC, animated: true, completion: { () -> Void in
        playerVC.playCurrentItem()
      })
    }
  }
  
  class SimpleAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String
    var zoneID: String
    var unwatched: Bool
    var isActive: Bool = false
    var isCurrentLocation = false
    
    init(coordinate coord: CLLocationCoordinate2D) {
      coordinate = coord
      title = "Me"
      zoneID = ""
      unwatched = false
    }
    
    init(zone: Zone) {
      coordinate = zone.coordinate
      title = zone.name
      zoneID = zone.zoneID
      isActive = zone.isActive
      unwatched = Bool(zone.freshContents.count)
    }
  }
}


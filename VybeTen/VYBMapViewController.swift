//
//  VYBMapViewController.swift
//  VybeTen
//
//  Created by jinsuk on 10/29/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//
import UIKit
import MapKit

@objc class VYBMapViewController: UIViewController, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    @IBAction func dismissButtonPressed(sender: AnyObject) {
        self.presentingViewController?.dismissViewControllerAnimated(false, completion: nil)
    }
    
    var _zonesOnScreen: [Zone]!
    var currLocation: MKAnnotation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setUpMapRegion()
        
        self.preloadZones()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    private func preloadZones() {
        if _zonesOnScreen != nil {
            for aZone in _zonesOnScreen {
                let simpleAnnotation = SimpleAnnotation(zone: aZone)
                mapView.addAnnotation(simpleAnnotation)
            }
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
            
            let annotation = SimpleAnnotation(coordinate: location)
            // this is current location annoation
            annotation.isCurrentLocation = true
            self.mapView.addAnnotation(annotation)
        }
    }
    
    private func moveMapToRegionAround(location: CLLocationCoordinate2D) {
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(location, span)
        mapView.setRegion(region, animated: false)
    }

    
    func displayAllActiveVybes() {
        _zonesOnScreen = ZoneStore.sharedInstance.activeZones()
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
        
        
        pin.canShowCallout = true
        
        let accessoryView = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as UIButton
        pin.rightCalloutAccessoryView = accessoryView
        

        if simpleAnnotation.unlocked {
            pin.image = UIImage(named: "map_blue_pin.png")
        }
        else {
            pin.image = UIImage(named: "map_red_pin.png")
        }
        
        return pin
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        let zone = view.annotation as SimpleAnnotation
        let playerVC = VYBPlayerViewController()
        self.presentViewController(playerVC, animated: true) { () -> Void in
            playerVC.playFreshVybesFromZone(zone.zoneID)
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
        return false
    }

    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }

    class SimpleAnnotation: NSObject, MKAnnotation {
        var coordinate: CLLocationCoordinate2D
        var title: String
        var zoneID: String
        var unlocked: Bool
        var isCurrentLocation = false
        
        init(coordinate coord: CLLocationCoordinate2D) {
            coordinate = coord
            title = "Me"
            zoneID = ""
            unlocked = false
        }
        
        init(zone: Zone) {
            coordinate = zone.coordinate
            title = zone.name
            zoneID = zone.zoneID
            unlocked = zone.unlocked
        }
    }
}

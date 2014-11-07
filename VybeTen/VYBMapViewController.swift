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
    
    var _zonesOnScreen: [VYBZone]!
    
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
                aZone.title = aZone.name
                mapView.addAnnotation(aZone)
            }
        }
    }
    
    private func setUpMapRegion() {
        // Somewhere in montreal
        let location = CLLocationCoordinate2DMake(45.503039, -73.570120)
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(location, span)
        
        mapView.setRegion(region, animated: false)
        mapView.delegate = self
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
        var pin = mapView.dequeueReusableAnnotationViewWithIdentifier("zonePin") as MKAnnotationView!

        if pin == nil {
            pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "zonePin")
        
            pin.canShowCallout = true
        }
        
        let accessoryView = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as UIButton
        pin.rightCalloutAccessoryView = accessoryView
        

        var zoneAnnotation = annotation as VYBZone
        if zoneAnnotation.unlocked {
            pin.image = UIImage(named: "map_blue_pin.png")
        }
        else {
            pin.image = UIImage(named: "map_red_pin.png")
        }
        
        return pin
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        let zone = view.annotation as VYBZone
        let playerVC = VYBPlayerViewController()
        self.presentViewController(playerVC, animated: true) { () -> Void in
            playerVC.playActiveVybesFromZone(zone.zoneID)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }


}

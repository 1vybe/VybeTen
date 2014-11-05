//
//  VYBMapViewController.swift
//  VybeTen
//
//  Created by jinsuk on 10/29/14.
//  Copyright (c) 2014 Vybe. All rights reserved.
//
import UIKit
import MapKit

class VYBMapViewController: UIViewController, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    @IBAction func dismissButtonPressed(sender: AnyObject) {
        self.presentingViewController?.dismissViewControllerAnimated(false, completion: nil)
    }
    
    var currAnnotation: MKAnnotation!
    var delegate: AnyObject!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setUpMapRegion()
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

    
    
    func displayVybes(vybes: [PFObject]) {
        for aVybe in vybes {
            if (mapView.annotations.count >= 30) {
                break
            }

            if let geoPoint = aVybe[kVYBVybeGeotag] as PFGeoPoint? {
                let vAnnotation = MKPointAnnotation()
                vAnnotation.coordinate = CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
                mapView.addAnnotation(vAnnotation)
            }
        }
    }
    
    func displayAllActiveVybes() {
        VYBUtility.fetchActiveZones { (zones: [AnyObject]!, error:NSError!) -> Void in
            if error == nil {
                if zones.count > 0 {
                    self.delegate.presentViewController(self, animated: true, completion: { () -> Void in
                        for aZone in zones as [VYBZone] {
                            aZone.title = aZone.name
                            self.mapView.addAnnotation(aZone)
                        }
                    })

                }
                else {
                    // There is no active zone
                }
            }
        }
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        var pin = mapView.dequeueReusableAnnotationViewWithIdentifier("zonePin") as MKAnnotationView!

        if pin == nil {
            pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "zonePin")
        }
        
        let accessoryView = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as UIButton
        pin.rightCalloutAccessoryView = accessoryView
        
        pin.canShowCallout = true
        
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


}

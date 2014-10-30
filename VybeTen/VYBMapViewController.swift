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
    
    func displayVybes(vybes: [PFObject]) {
        for aVybe in vybes {
            if (mapView.annotations.count >= 30) {
                break
            }

            let geoPoint = aVybe[kVYBVybeGeotag] as PFGeoPoint
            let location = CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
            let vAnnotation = MKPointAnnotation()
            vAnnotation.setCoordinate(location)
            
            mapView.addAnnotation(vAnnotation)
        }
    }
    
    func displayNearbyAroundVybe(aVybe: PFObject) {
        PFCloud.callFunctionInBackground("get_nearby_vybes", withParameters: ["vybeID": aVybe.objectId], { (objects: AnyObject!, error: NSError!) -> Void in
            if error == nil {
                self.displayVybes(objects as [PFObject])
            }
            self.displayCurrentVybe(aVybe)
        })
    }
    
    private func displayCurrentVybe(aVybe: PFObject) {
        let geoPoint = aVybe[kVYBVybeGeotag] as PFGeoPoint
        let location = CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
        let vAnnotation = MKPointAnnotation()
        vAnnotation.setCoordinate(location)

        currAnnotation = vAnnotation

        mapView.addAnnotation(vAnnotation)
        mapView.setNeedsDisplay()
    }
    
    private func setUpMapRegion() {
        let location = CLLocationCoordinate2DMake(45.503039, -73.570120)
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(location, span)
        
        mapView.setRegion(region, animated: false)
        mapView.delegate = self
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setUpMapRegion()
        // Do any additional setup after loading the view.
    }
    
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        var pin = mapView.dequeueReusableAnnotationViewWithIdentifier("vybePin") as MKPinAnnotationView?
        if  pin != nil {
            pin?.annotation = annotation
        }
        else {
            pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "vybePin")
        }
        
        if annotation.isEqual(currAnnotation) {
            pin?.pinColor = MKPinAnnotationColor.Green
        }
        else {
            pin?.pinColor = MKPinAnnotationColor.Red
        }
        
        return pin
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

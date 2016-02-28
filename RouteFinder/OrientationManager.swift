//
//  OrientationManager.swift
//  RouteFinder
//
//  Created by Renaud Amar on 2/27/16.
//  Copyright © 2016 Renaud Amar. All rights reserved.
//

// see these resources for location services:
// http://nshipster.com/cmdevicemotion/
// http://stackoverflow.com/questions/14070931/ios-calculating-distance-azimuth-elevation-and-relative-position-augmented
// http://www.dulaccc.me/2013/03/computing-the-ios-device-tilt.html

// magnetic heading:
// http://stackoverflow.com/questions/15380632/in-ios-what-is-the-difference-between-the-magnetic-field-values-from-the-core-l

// Code snippet to correct azimuth/heading based on device orientation/tilt angle:
// http://stackoverflow.com/questions/9260033/north-calculation-based-on-magnetometer-and-gyroscope

// More compass correction (haven't tried it - may not need):
// http://www.sundh.com/blog/2011/09/stabalize-compass-of-iphone-with-gyroscope/

// Simplified wrapper for orientation and motion:
// https://github.com/MHaroonBaig/MotionKit


import UIKit
import CoreLocation
import CoreMotion


protocol OrientationManagerDelegate: class {
    func didUpdateLatitude(latitude: Double)
    func didUpdateLongitude(longitude: Double)
    func didUpdateInclination(inclination: Double)
    func didUpdateAzimuth(azimuth: Double)
}


class OrientationManager: NSObject, CLLocationManagerDelegate {

    weak var delegate:OrientationManagerDelegate?
    
    var latitude: Double = 0.0 {
        didSet {
            delegate?.didUpdateLatitude(latitude)
        }
    }
    
    var longitude: Double = 0.0 {
        didSet {
            delegate?.didUpdateLongitude(longitude)
        }
    }

    var azimuth: Double = 0.0 {
        didSet {
            delegate?.didUpdateAzimuth(azimuth)
        }
    }
        
    var inclination: Double = 0.0 {
        didSet {
            delegate?.didUpdateInclination(inclination)
        }
    }
    
    var tiltAngle: Double = 0.0
    
    let locationManager: CLLocationManager = CLLocationManager()
    var startLocation: CLLocation!
    let motionManager = CMMotionManager()
    
    func start() {
        // setup the location manager
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        // start the location updates:
        locationManager.startUpdatingLocation()
        // start the heading updates:
        locationManager.startUpdatingHeading()
        startLocation = nil
        
        // setup the motion manager:
        // to get inclination and tilt updates
        if (motionManager.deviceMotionAvailable)
        {
            // set device motion updates every 0.1 seconds:
            motionManager.deviceMotionUpdateInterval = 0.1
            // set this to "pull" data
            //motionManager.startDeviceMotionUpdates()
            // or to push data:
            let queue = NSOperationQueue.mainQueue
            motionManager.startDeviceMotionUpdatesToQueue(queue()) {
                (data: CMDeviceMotion?, error: NSError?) in
                
                guard data != nil else {
                    print("There was an error: \(error)")
                    return
                }
                
                // calculate the tilt angle according to the gravity vector
                // this will be used to correct the azimuth:
                let gravityVector = CGPointMake(CGFloat(-data!.gravity.x), CGFloat(-data!.gravity.y))
                self.tiltAngle = self.calculateTiltAngle(gravityVector)
                
                // get the inclination:
                self.inclination = self.calculateInclination(data!)
            }
        }
    }

    
    func locationManager(manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation])
    {
        let latestLocation: AnyObject = locations[locations.count - 1]
        
        latitude = latestLocation.coordinate.latitude
        longitude = latestLocation.coordinate.longitude
        
        if startLocation == nil {
            startLocation = latestLocation as! CLLocation
        }
    }
    
    // get the azimuth:
    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading)
    {
        let az = locationManager.heading!.magneticHeading
        // compute corrected azimuth using the tilt angle:
        azimuth = fmod(az + tiltAngle, 360.0)
    }
    
    // this function calculates the device's tilt angle
    // (angle of the gravity vector in the device's referential):
    func calculateTiltAngle(vector: CGPoint) -> Double {
        let dX = vector.x
        let dY = vector.y
        
        if (dY == 0)
        {
            if (dX == 0) { return -1 }
            
            return dX > 0 ? 0.0 : 180.0
        }
        
        let beta = Utils.radiansToDegrees(Double(atan(dX/dY)));
        var angle : Double;
        
        if (dX > 0) {
            angle = dY < 0 ? 180 + beta : beta
        } else {
            angle = beta + (dY < 0 ? 180 : 360)
        }
        
        return angle;
    }
    
    // this function calculates the inclination angle given a CMDeviceMotion object
    // Depending on the orientation of the device, it will use either the pitch
    // or the roll to calculate the inclination and adjust it depending on gravity:
    func calculateInclination(motion: CMDeviceMotion) -> Double {
        // first determine the device orientation:
        let orientation = UIApplication.sharedApplication().statusBarOrientation;
        //let orientation = UIDevice.currentDevice().orientation
        
        var inclination : Double
        
        // get the inclination angle, in degrees:
        // - for portrait mode, the inclination is the pitch
        // - for landscape mode, it is the roll
        // and adjust it depending on the orientation
        switch orientation {
        case UIInterfaceOrientation.Unknown:
            inclination = 0
            break
        case UIInterfaceOrientation.Portrait:
            inclination = 90 - Utils.radiansToDegrees(motion.attitude.pitch)
            // adjust the sign depending on the z component of the gravity vector:
            inclination *= motion.gravity.z < 0 ? -1 : 1;
            break
        case UIInterfaceOrientation.PortraitUpsideDown:
            inclination = 90 - Utils.radiansToDegrees(motion.attitude.pitch)
            inclination *= motion.gravity.z < 0 ? 1 : -1;
            break
        case UIInterfaceOrientation.LandscapeLeft:
            inclination = Utils.radiansToDegrees(motion.attitude.roll) - 90.0
            break
        case UIInterfaceOrientation.LandscapeRight:
            inclination = -1.0*Utils.radiansToDegrees(motion.attitude.roll) - 90.0
            break
        }
        
        return inclination
    }
}

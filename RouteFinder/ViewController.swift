//
//  ViewController.swift
//  RouteFinder
//
//  Created by Renaud Amar on 8/9/15.
//  Copyright (c) 2015 Renaud Amar. All rights reserved.
//

import UIKit
import AVFoundation
import CoreLocation
import CoreMotion


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


func degreesToRadians(x: Double) -> Double {
    return (M_PI * (x) / 180.0)
}

func radiansToDegrees(x: Double) -> Double {
    return ((x) * 180.0 / M_PI)
}


class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var capturedImage: UIImageView!
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var orientationFinderView: OrientationFinderView!
    
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var altitudeLabel: UILabel!
    @IBOutlet weak var azimuthLabel: UILabel!
    @IBOutlet weak var inclinationLabel: UILabel!
    @IBOutlet weak var tiltLabel: UILabel!
    
    
    @IBOutlet weak var recLatitudeLabel: UILabel!
    @IBOutlet weak var recLongitudeLabel: UILabel!
    @IBOutlet weak var recAzimuthLabel: UILabel!
    @IBOutlet weak var recInclinationLabel: UILabel!
    
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var azimuth: Double = 0.0
    var inclination: Double = 0.0
    var tiltAngle: Double = 0.0
    
    var recLatitude: Double = 0.0
    var recLongitude: Double = 0.0
    var recAzimuth: Double = 0.0
    var recInclination: Double = 0.0
    
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    let locationManager: CLLocationManager = CLLocationManager()
    var startLocation: CLLocation!
    
    let motionManager = CMMotionManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
                self.tiltLabel.text = String(format: "Tilt: %.2f", self.tiltAngle)
                
                // get the inclination:
                self.inclination = self.calculateInclination(data!)
                self.inclinationLabel.text = String(format: "Inclination: %.4f", self.inclination)
                
                // update the orientation finder view:
                if (self.recInclination > 0) {
                    self.orientationFinderView.inclinationOffset = CGFloat(self.recInclination - self.inclination)
                    self.orientationFinderView.setNeedsDisplay()
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // create a capture session:
        captureSession = AVCaptureSession()
        captureSession!.sessionPreset = AVCaptureSessionPresetPhoto
        // select the back camera as capture device:
        let backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        // prepare to accept input on that device:
        var error: NSError?
        var input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput(device: backCamera)
        } catch let error1 as NSError {
            error = error1
            input = nil
        }
        // associate the input with the capture session:
        if error == nil && captureSession!.canAddInput(input) {
            captureSession!.addInput(input)
            
            // now setup the output:
            stillImageOutput = AVCaptureStillImageOutput()
            stillImageOutput!.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]

            if captureSession!.canAddOutput(stillImageOutput) {
                // associate the output with the capture session:
                captureSession!.addOutput(stillImageOutput)
                
                // now setup the live preview...
                // create the live preview layer and connect it with the capture session:
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                //previewLayer!.videoGravity = AVLayerVideoGravityResizeAspect
                //previewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.Portrait
                previewView.layer.addSublayer(previewLayer!)
                
                captureSession!.startRunning()
            }
            
            
            
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // set the bounds of the preview layer to match the bounds of the containing view:
        previewLayer!.frame = previewView.bounds
    }
    
    
    @IBAction func didPressTakePhoto(sender: UIButton) {
        
        // record the photo's coordinates:
        recLongitude = longitude
        recLatitude = latitude
        recAzimuth = azimuth
        recInclination = inclination
        
        // set the labels:
        recLatitudeLabel.text = String(format: "Latitude: %.4f", recLatitude)
        recLongitudeLabel.text = String(format: "Longitude: %.4f", recLongitude)
        recAzimuthLabel.text = String(format: "Azimuth: %.4f", recAzimuth)
        recInclinationLabel.text = String(format: "Inclination: %.4f", recInclination)
        
        // get connection object:
        if let videoConnection = stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo) {
            videoConnection.videoOrientation = AVCaptureVideoOrientation.Portrait
            
            // make a capture
            stillImageOutput?.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {(sampleBuffer, error) in
                if (sampleBuffer != nil) {
                    // get the image data:
                    var imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    // create a data provider with the image data:
                    var dataProvider = CGDataProviderCreateWithCFData(imageData)
                    // create a core graphics image using the data provider:
                    var cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, CGColorRenderingIntent.RenderingIntentDefault)
                    // and finally create a UUImage:
                    var image = UIImage(CGImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.Right)
                    // then assign the new image to our capturedImage:
                    self.capturedImage.image = image
                }
            })
        }
    }
    
    func locationManager(manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation])
    {
        let latestLocation: AnyObject = locations[locations.count - 1]
        
        latitude = latestLocation.coordinate.latitude
        longitude = latestLocation.coordinate.longitude
        
        latitudeLabel.text = String(format: "Latitude: %.4f", latitude)
        longitudeLabel.text = String(format: "Longitude: %.4f", longitude)
        altitudeLabel.text = String(format: "Altitude: %.4f", latestLocation.altitude)
        //horizontalAccuracy.text = String(format: "%.4f", latestLocation.horizontalAccuracy)
        //verticalAccuracy.text = String(format: "%.4f", latestLocation.verticalAccuracy)
        
        if startLocation == nil {
            startLocation = latestLocation as! CLLocation
        }
    }
    
    // get the azimuth:
    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading)
    {
        azimuth = locationManager.heading!.magneticHeading
        // compute corrected azimuth using the tilt angle:
        let correctedAzimuth = fmod(azimuth + tiltAngle, 360.0)
        azimuthLabel.text  = String(format: "Azimuth: %.2f %.2f", azimuth, correctedAzimuth)
        
        // update the orientation finder view:
        if (recAzimuth > 0) {
            orientationFinderView.azimuthOffset = CGFloat(recAzimuth - azimuth)
            orientationFinderView.setNeedsDisplay()
        }
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
    
        let beta = radiansToDegrees(Double(atan(dX/dY)));
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
            inclination = 90 - radiansToDegrees(motion.attitude.pitch)
            // adjust the sign depending on the z component of the gravity vector:
            inclination *= motion.gravity.z < 0 ? -1 : 1;
            break
        case UIInterfaceOrientation.PortraitUpsideDown:
            inclination = 90 - radiansToDegrees(motion.attitude.pitch)
            inclination *= motion.gravity.z < 0 ? 1 : -1;
            break
        case UIInterfaceOrientation.LandscapeLeft:
            inclination = radiansToDegrees(motion.attitude.roll) - 90.0
            break
        case UIInterfaceOrientation.LandscapeRight:
            inclination = -1.0*radiansToDegrees(motion.attitude.roll) - 90.0
            break
        }
        
        return inclination
    }

}


//
//  PhotoViewController.swift
//  RouteFinder
//
//  Created by Renaud Amar on 2/21/16.
//  Copyright © 2016 Renaud Amar. All rights reserved.
//

import UIKit
import AVFoundation


class PhotoViewController: UIViewController, OrientationManagerDelegate {
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var azimuthLabel: UILabel!
    @IBOutlet weak var inclinationLabel: UILabel!
    
    //var recLatitude: Double = 0.0
    //var recLongitude: Double = 0.0
    //var recAzimuth: Double = 0.0
    //var recInclination: Double = 0.0
    
    let orientationManager: OrientationManager = OrientationManager()
    
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // set the delegate for the orientation manager
        orientationManager.delegate = self
        orientationManager.start()
    }
    
    // we receive the updates from the OrientationManager through the following methods:
    func didUpdateLatitude(latitude: Double) {
        latitudeLabel.text = String(format: "Latitude:          %.4f", latitude)
    }
    
    func didUpdateLongitude(longitude: Double) {
        longitudeLabel.text = String(format: "Longitude:        %.4f", longitude)
    }
    
    func didUpdateAzimuth(azimuth: Double) {
        azimuthLabel.text  = String(format: "Azimuth:           %.2f", azimuth)
    }
    
    func didUpdateInclination(inclination: Double) {
        self.inclinationLabel.text = String(format: "Inclination:       %.2f", inclination)
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
                    //self.capturedImage.image = image
                    self.savePhotoToFileSystem(image)
                }
            })
        }
    }
    
    func savePhotoToFileSystem(image: UIImage) {
        let imageData = UIImageJPEGRepresentation(image, 1.0)
        let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        
        // format date to a string for photo filename:
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH.mm.ss"
        let photoFileName = String(format: "%@.jpg", dateFormatter.stringFromDate(NSDate()) )
        
        let imageURL = documentsURL.URLByAppendingPathComponent(photoFileName)
        
        // save the path to the NSUserDefaults for now (will save to DB later):
        // retrieve the current photo index:
        var photoIndex = NSUserDefaults.standardUserDefaults().integerForKey("photoIndex")

        if (imageData!.writeToURL(imageURL, atomically: false)) {
            // increment the stored photo index and store it:
            photoIndex++
            NSUserDefaults.standardUserDefaults().setInteger(photoIndex, forKey: "photoIndex")
            // save the current photo under the new index:
            NSUserDefaults.standardUserDefaults().setObject(photoFileName, forKey: String(format: "photoPath%d", photoIndex))
        }
        else {
            print ("writeToUrl failed")
        }

    }
    
}


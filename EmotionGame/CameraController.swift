//
//  CameraController.swift
//  EmotionGame
//
//  Created by Edward Beckett on 28/11/2019.
//  Copyright © 2019 Ed Beckett. All rights reserved.
//

import Foundation
import AVFoundation
import Vision
import SceneKit

class CameraController: NSObject {
    
    var session: AVCaptureSession?
    var imageOutput: AVCapturePhotoOutput?
    var picTimer: Timer?
    var Detector: FaceDetector?
    var expression = String()
    
    var defaults = UserDefaults.standard
    
    // thread
    var emotionQueue = DispatchQueue(label: "emotionQueue", qos: .userInitiated)
    
    override init() {
        super.init()
        // test for whether the user has allowed camera useage
        testPermission()
        
        // begin the face detection process on the emotion thread
        emotionQueue.async {
            self.Detector = FaceDetector()
        }
    }
    
    func setupTimer() {
        // setup the timer for looping
        // currently fires every second
        // calls the take photo method
        picTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.takePhoto), userInfo: nil, repeats: true)
        // allows the timer to fire 0.1s before or after the interval
        picTimer!.tolerance = 0.1
    }
    
    func testPermission() {
        // get the authorisation status of the camera
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: // The user has previously granted access to the camera.
            print("Camera allowed")
            self.setupCapture()
            
        case .notDetermined: // The user has not yet been asked for camera access.
            print("Camera Unknown")
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.setupCapture()
                }
            }
            
        case .denied: // The user has previously denied access.
            print("User has Camera Denied")
            // this does not allow the request of authorisation
            return
            
        case .restricted: // The user can't grant access due to restrictions.
            print("User has Camera restrictions")
            return
            
        default:
            print("Camera Authorization Error")
            return
        }
    }
    
    func setupCapture() {
        // Camera Setup
        session = AVCaptureSession()
        // Sets max quality
        session!.sessionPreset = AVCaptureSession.Preset.photo
        // Get front camera
        let Camera =  AVCaptureDevice.default(.builtInWideAngleCamera,for: AVMediaType.video,position: .front)
        var error: NSError?
        // Set input device.
        var input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput(device: Camera!)
        } catch let error1 as NSError {
            error = error1
            input = nil
            print(error!.localizedDescription)
        }
        
        if error == nil && session!.canAddInput(input) {
            session!.addInput(input)
            imageOutput = AVCapturePhotoOutput()
            if session!.canAddOutput(imageOutput!) {
                session!.addOutput(imageOutput!)
                session!.startRunning()
            }
        }
        
    }
    
    func passBack(result: String) {
        // called by the camera delegate to pass the expression back from the face detection class
        expression = result
    }
    
    func resetExpression() {
        // reset expression to default
        expression = "Neutral"
    }
    
    func getExpression() -> String {
        // called by the game to retrieve the expression
        return expression
    }
    
    @objc func takePhoto() {
        // ensuring that it can't take photos when the camera is denied...
        if ((session?.isRunning) != nil) {
            if session!.isRunning == true {
                // make sure user has not turned off camera in app settings
                if (defaults.bool(forKey: "NoCamera") == false) {
                    // in the emotion thread, take a picture
                    emotionQueue.async {
                        // set up photo settings
                        var photoSettings = AVCapturePhotoSettings()
                        
                        // Capture HEIF photos when supported. Enable auto-flash and high-resolution photos.
                        if  self.imageOutput!.availablePhotoCodecTypes.contains(.hevc) {
                            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
                        }
                        
                        // flash is set off by default
                        // this is the ideal situation as otherwise it would blind or distract players
                        // however, it may provide negative results when playing at night
                        
                        // may need to consider any photo manipulation techniques to enhance visibility
                        // for example, image stabilisation...
                        
                        // take image, calls the delegate to handle results
                        self.imageOutput!.capturePhoto(with: photoSettings, delegate: self)
                    }
                }
            }
        }
    }
}

extension CameraController: AVCapturePhotoCaptureDelegate  {
    
    // the delegate that handles photo outputs
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        // called just before the photo is about to be taken
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        // called after the photo is taken
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        // called after the photo has been processed
        
        // process the image/classify the face in the emotion thread
        emotionQueue.async {
            // get the image
            let cgImage = photo.cgImageRepresentation()?.takeUnretainedValue()
            // a few lines of code below may now be redundant due to the rotation only being used to display the image.
            // get the metadata for the image
            let metadata = photo.metadata
            // get the orientation of the image from the metadata
            let mdOrientation = metadata[kCGImagePropertyOrientation as String]
            
            // maybe handle this in a better way?
            // check if the orientation is not nil (image was not captured due to app closure)
            if mdOrientation != nil {
                // convert orientation to orientation for cgimages
                let cgOrientation = CGImagePropertyOrientation.init(rawValue: mdOrientation as! UInt32)
                // begin face detection, pass through image and the correct orientation
                self.Detector!.findFace(image: cgImage!, orientation: cgOrientation!)
                // retrieve the classified expression
                let expression = self.Detector!.getExpression()
                // pass back the expression to the camera class
                self.passBack(result: expression)
            }
        }
    }
}





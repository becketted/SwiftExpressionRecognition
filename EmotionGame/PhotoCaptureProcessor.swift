//
//  PhotoCaptureProcessor.swift
//  EmotionGame
//
//  Created by Edward Beckett on 18/11/2019.
//  Copyright © 2019 Ed Beckett. All rights reserved.
//

import Foundation
import AVFoundation

class PhotoCaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                              willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        print("Image capture about to occur")
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        print("Photo taken")
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput,
    didFinishProcessingPhoto photo: AVCapturePhoto,
    error: Error?) {
        //Image = SKSpriteNode(AVCapturePhoto)
    }
    
}

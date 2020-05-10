//
//  AudioPlayer.swift
//  EmotionGame
//
//  Created by Edward Beckett on 30/03/2020.
//  Copyright © 2020 Ed Beckett. All rights reserved.
//

import Foundation
import AVFoundation

class AudioPlayer: NSObject {
    
    var Player: AVAudioPlayer?
    var defaults = UserDefaults.standard
    override init() {
        super.init()
        
        let sound = Bundle.main.path(forResource: "Funk", ofType: "wav")
        
        do {
            Player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound!))
            Player?.enableRate = true
            // loop infinitely
            Player?.numberOfLoops = -1
        } catch {
            print(error)
        }
        
        if (defaults.bool(forKey: "NoVolume")) {
            Player?.volume = 0
        }
    }

    
    func play() {
        // allow playing of sound while phone in silent mode
        do {
           try AVAudioSession.sharedInstance().setCategory(.playback)
        } catch(let error) {
            print(error.localizedDescription)
        }
        Player?.play()
    }
    
    func pause() {
        //Player?.pause()
    }
    
    func stop(){
        Player?.stop()
    }
    
    func changeSpeed(speed: Float){
        Player?.rate = speed
    }
}

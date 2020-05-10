//
//  GameViewController.swift
//  EmotionGame
//
//  Created by Edward Beckett on 18/11/2019.
//  Copyright © 2019 Ed Beckett. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load 'GameScene.sks' as a GKScene. This provides gameplay related content
        // including entities and graphs.
        if let scene = MainMenu(fileNamed: "MainMenu") {
            
            // Set the scale mode to scale to fit the window
            scene.scaleMode = .aspectFill
                
            // Present the scene
            if let view = self.view as! SKView? {
                view.presentScene(scene)
                    
                view.ignoresSiblingOrder = true
                    
                //view.showsFPS = true
                //view.showsNodeCount = true
                view.showsFPS = false
                view.showsNodeCount = false
            }
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
           super.didReceiveMemoryWarning()
           // Release any cached data, images, etc that aren't in use.
    }
    
    
}

//
//  MainMenu.swift
//  EmotionGame
//
//  Created by Edward Beckett on 18/11/2019.
//  Copyright © 2019 Ed Beckett. All rights reserved.
//

import Foundation
import SpriteKit

class MainMenu: SKScene {
    
    /* UI Connections */
    var buttonPlay: MSButtonNode!
    
    var background = SKSpriteNode()
    var playButton = SKSpriteNode()
    var settingsButton = SKSpriteNode()
    var Title = SKSpriteNode()
    
    override func didMove(to view: SKView) {
        /* Setup your scene here */
        createBackground()
        createPlayButton()
        createSettingsButton()
        createTitle()
    }
    
    func loadGame() {
        /* 1) Grab reference to our SpriteKit view */
        guard let skView = self.view as SKView? else {
            print("Could not get Skview")
            return
        }
        
        /* 2) Load Game scene */
        guard let scene = GameScene(fileNamed:"GameScene") else {
            print("Could not make GameScene, check the name is spelled correctly")
            return
        }
        
        /* 3) Ensure correct aspect mode */
        scene.scaleMode = .aspectFill
        
        /* Show debug */
        //skView.showsPhysics = true
        //skView.showsDrawCount = true
        //skView.showsFPS = true
        //skView.showsNodeCount = true
        
        self.removeAllChildren()
        self.removeAllActions()
        
        /* 4) Start game scene */
        skView.presentScene(scene)
    }
    
    func loadSettings() {
        /* 1) Grab reference to our SpriteKit view */
        guard let skView = self.view as SKView? else {
            print("Could not get Skview")
            return
        }
        
        /* 2) Load Game scene */
        guard let scene = Settings(fileNamed:"Settings") else {
            print("Could not make GameScene, check the name is spelled correctly")
            return
        }
        
        /* 3) Ensure correct aspect mode */
        scene.scaleMode = .aspectFill
        
        /* Show debug */
        //skView.showsPhysics = true
        //skView.showsDrawCount = true
        //skView.showsFPS = true
        //skView.showsNodeCount = true
        
        self.removeAllChildren()
        self.removeAllActions()
        
        /* 4) Start game scene */
        skView.presentScene(scene)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches{
            let location = touch.location(in: self)
            if playButton.contains(location){
                loadGame()
            } else if settingsButton.contains(location) {
                loadSettings()
            }
        }
    }
    
    func createBackground() {
        background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: 0, y: 0)
        background.name = "background"
        background.size.height = self.size.height
        background.size.width = self.size.width
        background.zPosition = 0
        self.addChild(background)
    }
    
    func createPlayButton() {
        playButton = SKSpriteNode(imageNamed: "PlayButton")
        
        playButton.zPosition = 4
        playButton.position = CGPoint(x: 0, y: 0)
        playButton.size = CGSize(width: self.frame.width/2, height: self.frame.height/10)
        
        self.addChild(playButton)
    }
    
    func createSettingsButton() {
        settingsButton = SKSpriteNode(imageNamed: "SettingsButton")
        
        settingsButton.zPosition = 4
        settingsButton.position = CGPoint(x: 0, y: -self.frame.width/4)
        settingsButton.size = CGSize(width: self.frame.width/2, height: self.frame.height/10)
        
        self.addChild(settingsButton)
    }
    
    func createTitle() {
        Title = SKSpriteNode(imageNamed: "Title")
        
        Title.zPosition = 4
        Title.position = CGPoint(x: 0, y: self.frame.width/3)
        Title.size = CGSize(width: self.frame.width, height: self.frame.height/4)
        
        self.addChild(Title)
    }
    
}

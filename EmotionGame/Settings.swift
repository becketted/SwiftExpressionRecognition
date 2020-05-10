//
//  Settings.swift
//  EmotionGame
//
//  Created by Edward Beckett on 31/03/2020.
//  Copyright © 2020 Ed Beckett. All rights reserved.
//

import Foundation
import SpriteKit

class Settings: SKScene {
    
    // disable camera usage/emotion recognition through settings?? (on off)
    // volume? (on off)
    var defaults = UserDefaults.standard
    var background = SKSpriteNode()
    
    var camSwitch: UISwitch?
    var volSwitch: UISwitch?
    var methodSwitch: UISwitch?
    
    var volLabel = SKLabelNode()
    var camLabel = SKLabelNode()
    var methodLabel = SKLabelNode()
    
    var exitButton = SKSpriteNode()
    
    override func didMove(to view: SKView) {
        createBackground()
        createVolSwitch()
        createCamSwitch()
        createMethodSwitch()
        createVolLabel()
        createCamLabel()
        createMethodLabel()
        createExitButton()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches{
            let location = touch.location(in: self)
            if exitButton.contains(location) {
                //exitButton.removeFromParent()
                //exitButton = SKSpriteNode()
                
                //volLabel.removeFromParent()
                //camLabel.removeFromParent()
                
                //volSwitch?.removeFromSuperview()
                //camSwitch?.removeFromSuperview()
                for view in self.view!.subviews {
                    view.removeFromSuperview()
                }
                returnMenu()
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
    
    func createCamLabel(){
        camLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        camLabel.zPosition = 4
        camLabel.position = CGPoint(x: 0-self.frame.width/8, y: ((self.frame.height/2)/27.5) * 20.5)
        //(self.frame.height/2) * 0.9
        camLabel.name = "camLabel"
        camLabel.text = "Disable camera"
        camLabel.fontColor = UIColor.black
        camLabel.fontSize = 40
        camLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        camLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        self.addChild(camLabel)
    }
    
    func createVolLabel(){
        volLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        volLabel.zPosition = 4
        volLabel.position = CGPoint(x: 0-self.frame.width/8, y: ((self.frame.height/2)/27.5) * 10.5)
        volLabel.name = "volLabel"
        volLabel.text = "Disable volume"
        volLabel.fontColor = UIColor.black
        volLabel.fontSize = 40
        volLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        volLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        self.addChild(volLabel)
    }
    
    func createMethodLabel(){
        methodLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        methodLabel.zPosition = 4
        methodLabel.position = CGPoint(x: 0-self.frame.width/8, y: ((self.frame.height/2)/27.5) * 0.5)
        methodLabel.name = "methodLabel"
        methodLabel.text = "Method 1 / Method 2"
        methodLabel.fontColor = UIColor.black
        methodLabel.fontSize = 40
        methodLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        methodLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        self.addChild(methodLabel)
    }
    
    func createCamSwitch() {
        let camSwitch = UISwitch(frame:CGRect(x: self.frame.width * 0.4, y:self.frame.height * 0.06, width: 0, height: 0))
        camSwitch.isOn = true
        camSwitch.setOn(defaults.bool(forKey: "NoCamera"), animated: false)
        camSwitch.addTarget(self, action: #selector(camSwitchValueDidChange(_:)), for: .valueChanged)
        self.view!.addSubview(camSwitch)
    }
    
    func createVolSwitch() {
        let volSwitch = UISwitch(frame:CGRect(x: self.frame.width * 0.4, y: self.frame.height * 0.16, width: 0, height: 0))
        volSwitch.isOn = true
        volSwitch.setOn(defaults.bool(forKey: "NoVolume"), animated: false)
        volSwitch.addTarget(self, action: #selector(volSwitchValueDidChange(_:)), for: .valueChanged)
        self.view!.addSubview(volSwitch)
    }
    
    func createMethodSwitch() {
        let methodSwitch = UISwitch(frame:CGRect(x: self.frame.width * 0.4, y:self.frame.height * 0.26, width: 0, height: 0))
        methodSwitch.isOn = true
        methodSwitch.setOn(defaults.bool(forKey: "Method"), animated: false)
        methodSwitch.addTarget(self, action: #selector(methodSwitchValueDidChange(_:)), for: .valueChanged)
        self.view!.addSubview(methodSwitch)
    }
    
    @objc func volSwitchValueDidChange(_ sender: UISwitch!) {
        if (sender.isOn == true){
            print("vol disabled")
            defaults.set(true, forKey:"NoVolume")
        } else{
            print("vol enabled")
            defaults.set(false, forKey:"NoVolume")
        }
    }
    
    @objc func camSwitchValueDidChange(_ sender: UISwitch!) {
        if (sender.isOn == true){
            print("cam disabled")
            defaults.set(true, forKey:"NoCamera")
        }
        else{
            print("cam enabled")
            defaults.set(false, forKey:"NoCamera")
        }
    }
    
    @objc func methodSwitchValueDidChange(_ sender: UISwitch!) {
        if (sender.isOn == true){
            print("Method 2")
            defaults.set(true, forKey:"Method")
        }
        else{
            print("Method 1")
            defaults.set(false, forKey:"Method")
        }
    }
    
    func createExitButton() {
        exitButton = SKSpriteNode(imageNamed: "ExitButton")
        exitButton.zPosition = 4
        exitButton.position = CGPoint(x: 0, y: -self.frame.width*0.65)
        exitButton.size = CGSize(width: self.frame.width/2, height: self.frame.height/10)
        self.addChild(self.exitButton)
    }
    
    func returnMenu() {
        // Find menu view
        guard let skView = self.view as SKView? else {
            print("Error loading view")
            return
        }
        
        // Load menu scene
        guard let scene = MainMenu(fileNamed:"MainMenu") else {
            print("Error loading scene")
            return
        }
        
        // Ensure correct aspect ratio
        scene.scaleMode = .aspectFill
        
        // Debug options - not really needed for a menu
        //skView.showsPhysics = true
        //skView.showsDrawCount = true
        //skView.showsFPS = true
        
        // Switch scenes
        skView.presentScene(scene)
    }
}

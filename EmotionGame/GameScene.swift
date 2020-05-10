//
//  GameScene.swift
//  EmotionGame
//
//  Created by Edward Beckett on 18/11/2019.
//  Copyright © 2019 Ed Beckett. All rights reserved.
//

import SpriteKit
import GameplayKit
import AVFoundation
import Vision

struct CollisionBitMask {
    // To determine the collision categories
    static let birdCategory:UInt32 = 1 << 0
    static let groundCategory:UInt32 = 1 << 1
    static let scoreCategory:UInt32 = 1 << 2
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Variable declarations
    var Camera: CameraController!
    
    var Music: AudioPlayer!
    
    // Sprites
    var bird = SKSpriteNode()
    var Pipes = SKNode()
    var Floor = SKNode()
    
    // Textures
    let birdAtlas = SKTextureAtlas(named:"yellowbird")
    var birdSkins = Array<SKTexture>()
    
    // Actions
    var moveAndRemove = SKAction()
    var spawnDelay = SKAction()
    var spawnDelayForever = SKAction()
    var repeatActionBird = SKAction()
    
    // Speeds
    var moveSpeed = CGFloat(0.005)
    var actionSpeed = CGFloat(1.1)
    
    // States
    var isGameStarted = false
    var isDead = false
    
    // Emotion
    var expression = String("Neutral") {
        didSet {
            var myStr = "1f636"
            if expression == "Neutral" {
                myStr = "1f636"
            } else if expression == "Happy" {
                myStr = "1f60A"
            } else if expression == "Angry" {
                myStr = "1f620"
            } else if expression == "Surprised" {
                myStr = "1f62F"
            }
            if emotionLabel != nil {
                let str = String(Character(UnicodeScalar(Int(myStr, radix: 16)!)!))
                emotionLabel.text = str
                if expression != prevExpression {
                    emotionLabel.run(SKAction.sequence([
                        SKAction.scale(to: 1.5, duration: 0.1),
                        SKAction.scale(to: 1.0, duration: 0.1),
                    ]))
                }
            }
        }
    }
    var prevExpression = String("Neutral")
    var defaults = UserDefaults.standard
    
    // Game objects
    var pauseButton = SKSpriteNode()
    var background = SKSpriteNode()
    var scoreLabel = SKLabelNode()
    var tapPrompt = SKLabelNode()
    var emotionLabel = SKLabelNode()
    
    // Pause menu objects
    var blur = SKEffectNode()
    var exitButton = SKSpriteNode()
    var resumeButton = SKSpriteNode()
    
    // Lose menu objects
    var restartButton = SKSpriteNode()
    var finalScore = SKLabelNode()
    
    // Score
    var score = 0 {
        // Updates score
        didSet { scoreLabel.text = String(score) }
    }
    
    
    override func sceneDidLoad() {
        // Runs on initialisation
        self.createScene()
    }
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
    }
    
    func touchDown(atPoint pos : CGPoint) {
        // Unused
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        // Unused
    }
    
    func touchUp(atPoint pos : CGPoint) {
        // Unused
    }
    
    func moveFloor() {
        // Spawning, Movement and Removal of Floor Objects
        
        // Movement
        // Calculate required distance of travel
        let distance = CGFloat(self.frame.width * 1.5)
        // Set up movement based on distance and speed
        let move = SKAction.moveBy(x: -distance, y: 0, duration: TimeInterval(moveSpeed * distance))
        // Set up object removal for when they exit the screen
        let remove = SKAction.removeFromParent()
        // Combine into an action
        moveAndRemove = SKAction.sequence([move, remove])
        
        // Spawning
        let spawn = SKAction.run({
            // Spawn a new set of pipes
            self.Pipes = self.createPipes()
            self.addChild(self.Pipes)
            
            // Spawn a new floor
            self.Floor = self.createFloor(start: 0)
            self.addChild(self.Floor)
        })
        
        // Based on speed and distance, calculate the required delay.
        let delay = SKAction.wait(forDuration: Double((moveSpeed*distance)/3))
        // Combining spawning and a delay
        let spawnDelay = SKAction.sequence([spawn, delay])
        // Make it into a repeating action
        spawnDelayForever = SKAction.repeatForever(spawnDelay)
        // Run forever
        self.run(spawnDelayForever, withKey: "SpawnDelay")
    }
    
    func flapBird() {
        // Ensure bird is not moving
        self.bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        // Apply upwards veloctiy
        self.bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 90))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // If the game isn't paused or lost
        if isPaused == false && isDead == false {
            // If the game hasn't started
            if isGameStarted == false{
                // "Start" game
                isGameStarted =  true
                // As the screen was touched, make the bird flap
                flapBird()
                // Turn on gravity for the bird
                bird.physicsBody?.affectedByGravity = true
                // Hide tap prompt
                tapPrompt.removeFromParent()
                tapPrompt.removeAllActions()
                // Begin everything moving
                moveFloor()
                // As there is a unique floor at the start, move that
                self.Floor.run(self.moveAndRemove, withKey: "MoveRemove")
                // Bird animation
                self.bird.run(self.repeatActionBird)
                
                Camera.setupTimer()
                Music.play()
            } else {
                // If game is running
                for touch in touches{
                    let location = touch.location(in: self)
                    // If the pause button is pressed
                    if pauseButton.contains(location){
                        // Blur the screen, draw the menu and pause the gameplay
                        self.createBlur()
                        self.createPauseMenu()
                        self.pauseButton.removeFromParent()
                        if (defaults.bool(forKey: "NoCamera") == false) {
                            self.emotionLabel.removeFromParent()
                        }
                        isPaused = true
                        
                        Camera.picTimer?.invalidate()
                        Music.stop()
                    } else {
                        // If pause button isn't pressed, then flap the bird
                        flapBird()
                    }
                }
            }
        } else {
            // If game is paused/lost
            for touch in touches{
                let location = touch.location(in: self)
                // If resume button is pressed
                if resumeButton.contains(location){
                    Camera.setupTimer()
                    Music.play()
                    // Undraw the pause menu and resume gameplay
                    // Remove both buttons and reset to ensure they do not recieve further inputs
                    resumeButton.removeFromParent()
                    resumeButton = SKSpriteNode()
                    
                    exitButton.removeFromParent()
                    exitButton = SKSpriteNode()
                    
                    blur.removeFromParent()
                    createPauseButton()
                    createEmotionLabel()
                    isPaused = false
                // If restart button is pressed
                } else if restartButton.contains(location){
                    restartButton.removeFromParent()
                    restartButton = SKSpriteNode()
                    exitButton.removeFromParent()
                    exitButton = SKSpriteNode()
                    
                    blur.removeFromParent()
                    createPauseButton()
                    createScoreLabel()
                    createEmotionLabel()
                    restartScene()
                // If exit button is pressed
                } else if exitButton.contains(location){
                    // Undraw pause menu, resume gameplay but return to the main menu
                    resumeButton.removeFromParent()
                    resumeButton = SKSpriteNode()
                    restartButton.removeFromParent()
                    restartButton = SKSpriteNode()
                    exitButton.removeFromParent()
                    exitButton = SKSpriteNode()
                    
                    self.blur.removeFromParent()
                    isPaused = false
                    returnMenu()
                }
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Check for collision between Bird and scoring box within pipes
        if (contact.bodyA.categoryBitMask & CollisionBitMask.scoreCategory) == CollisionBitMask.scoreCategory || (contact.bodyB.categoryBitMask & CollisionBitMask.scoreCategory) == CollisionBitMask.scoreCategory {
            // Update scoring
            score += 1
            // Score animation
            scoreLabel.run(SKAction.sequence([
                SKAction.scale(to: 1.5, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1),
            ]))
        }
        // Check for collision between Bird and obstacles
        if contact.bodyA.categoryBitMask == CollisionBitMask.birdCategory && contact.bodyB.categoryBitMask == CollisionBitMask.groundCategory || contact.bodyA.categoryBitMask == CollisionBitMask.groundCategory && contact.bodyB.categoryBitMask == CollisionBitMask.birdCategory {
            // If not already dead...
            if isDead == false{
                // End game and restart
                isDead = true
                stopMovement()
                Camera.picTimer?.invalidate()
                Music.stop()
                
                createBlur()
                createLoseMenu()
                pauseButton.removeFromParent()
                scoreLabel.removeFromParent()
                emotionLabel.removeFromParent()
                bird.removeFromParent()
            }
        }
    }
    
    func beginCamera() {
        // Sets up camera
        self.Camera = CameraController()
    }
    
    func setupMusic() {
        self.Music = AudioPlayer()
    }
    
    func stopMovement() {
        self.removeAllActions()
        for object in self.children {
            object.removeAllActions()
        }
        bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        bird.physicsBody?.affectedByGravity = false
    }
    
    func returnMenu() {
        // Stop looping camera timer
        Camera.picTimer?.invalidate()
        Music.stop()
        
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
    
    override func update(_ currentTime: TimeInterval) {
        // Ensure game is actually running
        if isGameStarted == true {
            // Check game isn't paused or player has lost
            if isPaused == false && isDead == false {
                
                // Bird rotation
                let clamp = CGFloat(0.5)
                var rotationAmount = (bird.physicsBody?.velocity.dy ?? 0) / 1000
                if rotationAmount > clamp {
                    rotationAmount = clamp
                } else if rotationAmount < -clamp {
                    rotationAmount = -clamp
                }
                bird.zRotation = rotationAmount
                
                // Run in other thread
                Camera.emotionQueue.async {
                    // Ensure emotion is set
                    if self.Camera.getExpression() != "" {
                        // Get emotion
                        self.expression = self.Camera.getExpression()
                    }
                    
                    // If emotion has changed
                    if (self.hasExpressionChanged()){
                        // Update previous expression for next time
                        self.prevExpression = self.expression
                        
                        // Set action speed accordingly to emotion
                        switch self.expression {
                        case "Happy":
                            self.actionSpeed = 1.4
                        case "Angry":
                            self.actionSpeed = 0.8
                        case "Surprised":
                            self.actionSpeed = 0.9
                        default:
                            self.actionSpeed = 1.1
                        }
                    }
                    
                    // Respond to emotion accordingly in main thread.
                    DispatchQueue.main.async {
                        // Modify action speed for spawning and delay
                        self.action(forKey: "SpawnDelay")?.speed = self.actionSpeed
                        // For each object currently running the move and remove action
                        for object in self.children {
                            // Modify action speed for movement and removal
                            object.action(forKey: "MoveRemove")?.speed = self.actionSpeed
                        }
                        
                        if self.actionSpeed == 1.4 {
                            self.Music.changeSpeed(speed: 1.05)
                        } else if self.actionSpeed == 0.8 {
                            self.Music.changeSpeed(speed: 0.9)
                        } else if self.actionSpeed == 0.9 {
                            self.Music.changeSpeed(speed: 0.95)
                        } else {
                            self.Music.changeSpeed(speed: 1)
                        }
                        
                    }
                }
            }
        }
    }
    
    func hasExpressionChanged() -> Bool {
        if expression != prevExpression {
            return true
        } else {
            return false
        }
    }
    
    func createBird() -> SKSpriteNode {
        let bird = SKSpriteNode(imageNamed: "yellowbird-midflap")
        bird.size = CGSize(width: 68, height: 48)
        bird.position = CGPoint(x:self.frame.midX, y:self.frame.midY)
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.width / 2.5)
        bird.physicsBody?.linearDamping = 1.1
        bird.physicsBody?.restitution = 0
        bird.physicsBody?.allowsRotation = false
        
        bird.physicsBody?.categoryBitMask = CollisionBitMask.birdCategory
        bird.physicsBody?.collisionBitMask = CollisionBitMask.groundCategory
        bird.physicsBody?.contactTestBitMask = CollisionBitMask.groundCategory
        
        bird.physicsBody?.affectedByGravity = false
        bird.physicsBody?.isDynamic = true
        
        bird.zPosition = 3
        
        return bird
    }
    
    func createPipes() -> SKNode {
        let PipeTop = SKSpriteNode(imageNamed: "Pipe")
        let PipeBottom = SKSpriteNode(imageNamed: "Pipe")
        
        // positioning
        PipeTop.position = CGPoint(x: (self.frame.width/2) + (PipeTop.size.width/2), y: (self.frame.height/9) + (PipeTop.size.height/2))
        PipeBottom.position = CGPoint(x: (self.frame.width/2) + (PipeBottom.size.width/2), y: -(self.frame.height/9) - (PipeBottom.size.height/2))
        PipeTop.zRotation = CGFloat(Double.pi)
        
        PipeTop.physicsBody = SKPhysicsBody(rectangleOf: PipeTop.size)
        
        PipeTop.physicsBody?.categoryBitMask = CollisionBitMask.groundCategory
        PipeTop.physicsBody?.collisionBitMask = CollisionBitMask.birdCategory
        PipeTop.physicsBody?.contactTestBitMask = CollisionBitMask.birdCategory
        
        PipeTop.physicsBody?.isDynamic = false
        PipeTop.physicsBody?.affectedByGravity = false
        
        PipeBottom.physicsBody = SKPhysicsBody(rectangleOf: PipeBottom.size)
        
        PipeBottom.physicsBody?.categoryBitMask = CollisionBitMask.groundCategory
        PipeBottom.physicsBody?.collisionBitMask = CollisionBitMask.birdCategory
        PipeBottom.physicsBody?.contactTestBitMask = CollisionBitMask.birdCategory
        
        PipeBottom.physicsBody?.isDynamic = false
        PipeBottom.physicsBody?.affectedByGravity = false
        
        PipeTop.zPosition = 1
        PipeBottom.zPosition = 1
        
        // Scoring box
        let ScoreSection = SKSpriteNode()
        ScoreSection.position = CGPoint(x: (self.frame.width/2) + ((PipeTop.size.width/3)*2.5), y: 0)
        ScoreSection.size = CGSize(width:PipeTop.frame.width/3, height:self.frame.height/4.5)
        ScoreSection.physicsBody = SKPhysicsBody(rectangleOf: ScoreSection.size)
        ScoreSection.physicsBody?.categoryBitMask = CollisionBitMask.scoreCategory
        ScoreSection.physicsBody?.contactTestBitMask = CollisionBitMask.birdCategory
        ScoreSection.physicsBody?.isDynamic = false
        ScoreSection.physicsBody?.affectedByGravity = false
        
        Pipes = SKNode()
        Pipes.name = "Pipes"
        
        
        self.Pipes.addChild(PipeTop)
        self.Pipes.addChild(PipeBottom)
        
        // Scoring Box
        self.Pipes.addChild(ScoreSection)
        
        
        // random placement
        let minHeight =  Int((0 - (self.frame.height/2)) + (self.frame.height/4.5) + (self.frame.height/9) + (PipeBottom.size.height/10))
        let maxHeight = Int((self.frame.height/2) - (self.frame.height/9) - (PipeBottom.size.height/10))
        let randomPosition = CGFloat(Int.random(in: minHeight...maxHeight))
        Pipes.position.y = randomPosition
        
        if isGameStarted == true && isPaused == false && isDead == false{
            //Pipes.run(moveAndRemovePipes)
            
            self.Pipes.run(self.moveAndRemove, withKey: "MoveRemove")
            
        }
        
        print("creating pipes")
        return Pipes
    }
    
    func createFloor(start: Int) -> SKNode {
        let FLR = SKSpriteNode(imageNamed: "Floor")
        
        // middle of screen
        if start == 1 {
            FLR.position = CGPoint(x: 0, y: (-self.frame.height/2) + (FLR.size.height/2))
        } else {
            FLR.position = CGPoint(x: self.frame.width, y: (-self.frame.height/2) + (FLR.size.height/2))
        }
        
        FLR.physicsBody = SKPhysicsBody(rectangleOf: FLR.size)
        
        FLR.physicsBody?.isDynamic = false
        FLR.physicsBody?.affectedByGravity = false
        
        FLR.physicsBody?.categoryBitMask = CollisionBitMask.groundCategory
        FLR.physicsBody?.collisionBitMask = CollisionBitMask.birdCategory
        FLR.physicsBody?.contactTestBitMask = CollisionBitMask.birdCategory
        
        FLR.physicsBody?.friction = 1.0
        
        FLR.zPosition = 2
        
        Floor = SKNode()
        Floor.name = "Floor"
        
        self.Floor.addChild(FLR)
        
        if isGameStarted == true && isPaused == false && isDead == false {
            self.Floor.run(self.moveAndRemove, withKey: "MoveRemove")
        }
        
        return Floor
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
    
    func createPauseButton(){
        pauseButton = SKSpriteNode(imageNamed: "pause")
        pauseButton.zPosition = 4
        pauseButton.size = CGSize(width:self.frame.width/8, height:self.frame.width/8)
        pauseButton.position = CGPoint(x: -(self.frame.width/2) + (self.frame.width/12), y: (self.frame.height/2) - (self.frame.width/12))
        pauseButton.name = "pausebutton"
        self.addChild(pauseButton)
    }
    
    func createScoreLabel(){
        scoreLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        scoreLabel.zPosition = 4
        scoreLabel.position = CGPoint(x: (self.frame.width/2) - (self.frame.width/12), y: (self.frame.height/2) - (self.frame.width/12))
        scoreLabel.name = "scorelabel"
        scoreLabel.text = String(score)
        scoreLabel.fontColor = UIColor.black
        scoreLabel.fontSize = 70
        scoreLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        self.addChild(scoreLabel)
    }
    
    func createEmotionLabel() {
        //emotionLabel = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        emotionLabel.zPosition = 4
        emotionLabel.position = CGPoint(x: 0, y: (self.frame.height/2) - (self.frame.width/12))
        emotionLabel.name = "emotionLabel"
        let myStr = "1f636"
        let str = String(Character(UnicodeScalar(Int(myStr, radix: 16)!)!))
        //emotionLabel.text = String(format: "%C", 0xe04f)
        emotionLabel.text = str
        emotionLabel.fontSize = 70
        emotionLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        emotionLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center

        if (defaults.bool(forKey: "NoCamera") == false) {
            self.addChild(emotionLabel)
        }
    }
    
    func createBlur(){
        let blurImage = SKSpriteNode(imageNamed: "plain")
        blurImage.size = CGSize(width: self.frame.width, height: self.frame.height)
        blurImage.position = CGPoint(x: 0, y: 0)
        
        blur = SKEffectNode()
        blur.shouldRasterize = true
        blur.zPosition = 4
        blur.alpha = 0.3
        blur.addChild(SKSpriteNode(texture: blurImage.texture))
        blur.position = CGPoint(x: 0, y: 0)
        blur.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius":30])
        
        self.addChild(self.blur)
        
    }
    
    func createPauseMenu(){
        resumeButton = SKSpriteNode(imageNamed: "ResumeButton")
        exitButton = SKSpriteNode(imageNamed: "ExitButton")
        
        resumeButton.zPosition = 4
        resumeButton.position = CGPoint(x: 0, y: self.frame.width/6)
        resumeButton.size = CGSize(width: self.frame.width/2, height: self.frame.height/10)
        
        exitButton.zPosition = 4
        exitButton.position = CGPoint(x: 0, y: -self.frame.width/6)
        exitButton.size = CGSize(width: self.frame.width/2, height: self.frame.height/10)
        
        self.addChild(self.resumeButton)
        self.addChild(self.exitButton)
        
    }
    
    func createLoseMenu() {
        restartButton = SKSpriteNode(imageNamed: "RestartButton")
        exitButton = SKSpriteNode(imageNamed: "ExitButton")
        
        restartButton.zPosition = 4
        restartButton.position = CGPoint(x: 0, y: self.frame.width/6)
        restartButton.size = CGSize(width: self.frame.width/2, height: self.frame.height/10)
        
        exitButton.zPosition = 4
        exitButton.position = CGPoint(x: 0, y: -self.frame.width/6)
        exitButton.size = CGSize(width: self.frame.width/2, height: self.frame.height/10)
        
        
        finalScore = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        finalScore.zPosition = 4
        finalScore.position = CGPoint(x: 0, y: self.frame.width/2)
        finalScore.name = "finalScore"
        finalScore.text = String("Your Score: \(score)")
        finalScore.fontColor = UIColor.black
        finalScore.fontSize = 80
        finalScore.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        finalScore.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        
        self.addChild(finalScore)
        self.addChild(restartButton)
        self.addChild(exitButton)
    }
    
    func createTapPrompt() {
        tapPrompt = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        tapPrompt.zPosition = 4
        tapPrompt.position = CGPoint(x: 0, y: self.frame.width/3)
        tapPrompt.name = "finalScore"
        tapPrompt.text = String("Tap to Flap!")
        tapPrompt.fontColor = UIColor.black
        tapPrompt.fontSize = 80
        tapPrompt.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        tapPrompt.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        
        self.addChild(tapPrompt)
    }
    
    func createScene(){
        // Set up camera
        beginCamera()
        setupMusic()
        // Ensure score is set to 0
        score = 0
        // Set up various static features
        createBackground()
        createPauseButton()
        createScoreLabel()
        createEmotionLabel()
        createTapPrompt()
        // Animate tap prompt
        let promptAnimation = SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.scale(to: 1.2, duration: 0.05),
            SKAction.scale(to: 1.0, duration: 0.3),
        ])
        // Make it into a repeating action
        let loopingPromptAnimation = SKAction.repeatForever(promptAnimation)
        // Run forever
        tapPrompt.run(loopingPromptAnimation)
        // Create initial set of pipes
        Pipes = createPipes()
        self.addChild(Pipes)
        // Create initial floor in unique position
        Floor = createFloor(start: 1)
        self.addChild(Floor)
        // Create bird
        bird = createBird()
        self.addChild(bird)
        // Add bird images to atlas for different stages of flight
        birdSkins.append(birdAtlas.textureNamed("yellowbird-midflap"))
        birdSkins.append(birdAtlas.textureNamed("yellowbird-downflap"))
        birdSkins.append(birdAtlas.textureNamed("yellowbird-midflap"))
        birdSkins.append(birdAtlas.textureNamed("yellowbird-upflap"))
        // Define bird flapping animation
        let animateBird = SKAction.animate(with: self.birdSkins, timePerFrame: 0.1)
        self.repeatActionBird = SKAction.repeatForever(animateBird)
        
        // Set physics boundary of frame
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        // Define collision rules
        self.physicsBody?.categoryBitMask = CollisionBitMask.groundCategory
        self.physicsBody?.collisionBitMask = CollisionBitMask.birdCategory
        self.physicsBody?.contactTestBitMask = CollisionBitMask.birdCategory
        // Ensure frame border doesn't move
        self.physicsBody?.isDynamic = false
        self.physicsBody?.affectedByGravity = false
    }
    
    func restartScene(){
        self.removeAllActions()
        for object in self.children  {
            object.removeAllActions()
            object.removeFromParent()
        }
        
        isPaused = false
        isDead = false
        isGameStarted = false
        
        Camera.resetExpression()
        moveSpeed = 0.005
        
        self.createScene()
    }
    
}

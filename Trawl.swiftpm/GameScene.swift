//
//  GameScene.swift
//  Trawl
//
//  Created by 송지혁 on 2/15/24.
//

import AVKit
import GameController
import SpriteKit

struct PhysicsCategory {
    static let Obstacle: UInt32 = 0b10000
    static let Marlin: UInt32 = 0b10
    static let Slash: UInt32 = 0b100
    static let TrawlingNet: UInt32 = 0b1000
    static let Corals: UInt32 = 0b1
    static let Line: UInt32 = 0b100000
}

class GameScene: SKScene, SKPhysicsContactDelegate, ObservableObject {
    @Published var tutorialState: TutorialState?
    @Published var co2Concentration: CGFloat = 0.0
    @Published var life: CGFloat = 3.0
    @Published var isGameOver = false
    @Published var tutorialComplete = false
    @Published var cause = ""
    
    let soundManager = SoundManager()
    var startTime: TimeInterval = 0
    var endTime: TimeInterval = 0
    var playtime: TimeInterval = 0
    
    var backgroundBoids: [BoidNode] = []
    var backgroundBoids2: [BoidNode] = []
    var fishes: [SKSpriteNode] = []
    
    var marlinNode = SKSpriteNode()
    var slashNode = SKSpriteNode()
    
    var cameraNode = SKCameraNode()
    var coralNodes: [SKSpriteNode] = []
    
    var co2Supersaturation = false
    var virtualController: GCVirtualController?
    var stun = false
    var isCollide = false
    
    var cutNet: Int = 0
    
    var netCount = 0
    var maxNetCount = 3
    
    var coralCollisionStartTime = 0.0
    
    var lastUpdateTime: TimeInterval = 0.0
    var timeSinceLastNetCreation: TimeInterval = 0.0
    var netCreationInterval: TimeInterval = 6.0
    
    var backgroundWidth: CGFloat = 0
    var firstBackgroundNode = SKSpriteNode()
    var secondBackgroundNode = SKSpriteNode()
    
    var firstFloorNode = SKSpriteNode()
    var secondFloorNode = SKSpriteNode()
    
    var playerVelocity = CGVector.zero // 플레이어의 속도
    var playerSpeed: CGFloat {
        sqrt(playerVelocity.dx * playerVelocity.dx + playerVelocity.dy * playerVelocity.dy)
    }
    var isSlashAnimationRunning = false
    var lastObstacleYPosition: CGFloat?
    
    
    var slashFrames: [SKTexture] = []
    var swimmingFrames: [SKTexture] = []
    
    
    let acceleration: CGFloat = 0.2 // 가속도
    let deceleration: CGFloat = 0.03
    var bubbleNode = SKEmitterNode()
    
    var currentTimePerFrame: CGFloat = 0.0
    var maxSpeed: CGFloat = 2.3
    
    var stickInputX: CGFloat = 0.0
    var stickInputY: CGFloat = 0.0
    
    var minX: CGFloat = UIScreen.main.bounds.width * 0.1
    var maxX: CGFloat = UIScreen.main.bounds.width * 1.9
    var minY: CGFloat = UIScreen.main.bounds.height * 0.1
    var maxY: CGFloat = UIScreen.main.bounds.height * 0.9
    
    deinit {
        self.removeAllActions()
        self.removeAllChildren()
    }
    
    override func didMove(to view: SKView) {
        self.size = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        self.scaleMode = .aspectFill
        self.anchorPoint = CGPoint(x: 0, y: 0)
        self.physicsWorld.contactDelegate = self
        
        if !tutorialComplete {
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                self.tutorial()
            }
        }
        
        createFloor()
        createBackground()
        
        for _ in 0..<100 {
            let boid = BoidNode(imageNamed: "fish_1")
            boid.position = CGPoint(x: CGFloat.random(in: minX...maxX),
                                    y: CGFloat.random(in: minY...maxY))
            boid.size = CGSize(width: 10, height: 10)
           addChild(boid)
           backgroundBoids.append(boid)
        }
        
        for _ in 0..<40 {
            let boid = BoidNode(imageNamed: "fish_2")
            boid.position = CGPoint(x: CGFloat.random(in: minX...maxX),
                                    y: CGFloat.random(in: minY...maxY))
            boid.size = CGSize(width: 10, height: 10)
           addChild(boid)
           backgroundBoids.append(boid)
        }
        addFishes()
        
        
        
        for i in 1...6 {
            self.slashFrames.append(SKTexture(imageNamed: "marlin_slash_\(i)"))
        }
        
        for i in 1...21 {
            self.swimmingFrames.append(SKTexture(imageNamed: "marlin_swimming_\(i)"))
        }
//        SKTexture.preload(self.swimmingFrames) {
//            SKTexture.preload(self.slashFrames) {
                self.makeMarlin()
                self.createBackground()
                self.setupCamera()
                self.bubbleEmitter(position: CGPoint(x: 33, y: 0))
//            }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        let nodeA = contact.bodyA.node
        let nodeB = contact.bodyB.node
        
        if contactMask == PhysicsCategory.TrawlingNet | PhysicsCategory.Marlin {
            if isCollide {
                return
            }
            
            self.life -= 1
            
            self.isCollide = true
            
            
            let blinkAction = SKAction.sequence([
                SKAction.fadeAlpha(to: 0, duration: 0.3),
                SKAction.fadeAlpha(to: 1, duration: 0.3)])

            let blinkRepeatAction = SKAction.repeat(blinkAction, count: 5)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.isCollide = false
                self.marlinNode.alpha = 1
                
            }
            marlinNode.run(blinkRepeatAction)
        }
        
        if contactMask == PhysicsCategory.Line | PhysicsCategory.Slash {
            let fadeOut = SKAction.fadeOut(withDuration: 1)
            if nodeA?.physicsBody?.categoryBitMask == PhysicsCategory.Line {
                nodeA?.parent?.run(fadeOut) {
                    nodeA?.parent?.removeAllActions()
                    nodeA?.parent?.removeFromParent()
                    self.removeAction(forKey: "CO2Increment_\(self.netCount)")
                    self.netCount -= 1
                    self.cutNet += 1
                    self.soundManager.playSound(sound: .scissor, volume: 0.1, repeatForever: false)
                }
                
            } else {
                nodeB?.parent?.run(fadeOut) {
                    nodeB?.parent?.removeAllActions()
                    nodeB?.parent?.removeFromParent()
                    self.removeAction(forKey: "CO2Increment_\(self.netCount)")
                    self.netCount -= 1
                    self.cutNet += 1
                    self.soundManager.playSound(sound: .scissor, volume: 0.1, repeatForever: false)
                }
            }
        }
        
        if contactMask == PhysicsCategory.Marlin | PhysicsCategory.Corals {
            self.life += 1
        }
    }
    
    func gameOver() {
        virtualController?.disconnect()
        virtualController = nil
        endTime = Date().timeIntervalSince1970
        playtime = endTime - startTime
        isGameOver = true
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        if !isGameOver {
            if Int(self.life) <= 0 {
                cause = "injuries caused by a fishing net"
                gameOver()
            }
            if co2Concentration >= 100 {
                cause = "suffocation due to ocean acidification"
                gameOver()
            }
        }
        
        if !stun {
            applyPlayerStickMove()
        }
        
        self.life = min(max(life, 0), 3)
        
        timeSinceLastNetCreation += currentTime - lastUpdateTime
            lastUpdateTime = currentTime
        
        if timeSinceLastNetCreation >= netCreationInterval && self.netCount < maxNetCount {
                self.createNet()
            timeSinceLastNetCreation = 0.0
            }
        
        
        if !backgroundBoids.isEmpty {
            for boid in backgroundBoids {
                boid.update(with: backgroundBoids, bounds: self.frame, padding: 50, maxSpeed: 5)
            }
        }
        
        if !backgroundBoids2.isEmpty {
            
            for boid in backgroundBoids2 {
                boid.update(with: backgroundBoids2, bounds: self.frame, padding: 50, maxSpeed: 2)
            }
        }
        
        updateMarlinPosition()
        cameraNode.position = marlinNode.position
        
        if !co2Supersaturation {
            if co2Concentration > 50 {
                bleachedCorals()
                removeAllFishes()
                co2Supersaturation = true
                self.maxNetCount = 5
                self.maxSpeed /= 1.5
                self.netCreationInterval = 2
            }
        }
        
        if stickInputX < 0 {
            self.slashNode.position = CGPoint(x: marlinNode.position.x - 40, y: marlinNode.position.y)
        } else {
            self.slashNode.position = CGPoint(x: marlinNode.position.x + 40, y: marlinNode.position.y)
        }
        
    }
    
    func restartGame() {
        self.removeAllActions()
        self.removeAllChildren()
        self.makeVirtualController()
        self.tutorialComplete = true
        self.makeVirtualController()
        self.isGameOver = false
        self.co2Concentration = 0
        self.netCount = 0
        self.endTime = 0
        self.playtime = 0
        self.netCount = 0
        self.cutNet = 0
        self.coralCollisionStartTime = 0
        self.life = 3
        
        self.playerVelocity = CGVector.zero
        self.co2Supersaturation = false
        
        self.isSlashAnimationRunning = false
        self.lastUpdateTime = 0.0
        self.timeSinceLastNetCreation = 0.0
        
        self.currentTimePerFrame = 0.0
    }
    
    func makeVirtualController() {
        let controllerConfiguration = GCVirtualController.Configuration()
        controllerConfiguration.elements = [GCInputLeftThumbstick]
        
        let controller = GCVirtualController(configuration: controllerConfiguration)
        
        controller.connect { error in
            guard let error = error else { return }
        }
        virtualController = controller
    }
    
    func dash() {
        self.playerVelocity.dx *= 3
        self.playerVelocity.dy *= 3
        self.maxSpeed *= 3
        self.bubbleNode.particlePositionRange = CGVector(dx: 4, dy: 6)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.playerVelocity.dx /= 3
            self.playerVelocity.dy /= 3
            self.maxSpeed /= 3
            self.bubbleNode.particlePositionRange = CGVector(dx: 2, dy: 1)
        }
    }
    
    func slash() {
        applySlashAnimation()
        applySlashHitBox()
    }
    
    func isSlashAnimationActivate() -> Bool {
        return isSlashAnimationRunning
    }
    
    func applySlashHitBox() {
        let nodeSize = CGSize(width: 75, height: 150)
        let slashNode = SKSpriteNode(color: .clear, size: nodeSize)
        let physics = SKPhysicsBody(rectangleOf: nodeSize)
        physics.categoryBitMask = PhysicsCategory.Slash
        physics.contactTestBitMask = PhysicsCategory.Obstacle | PhysicsCategory.Line
        physics.collisionBitMask = 0
        physics.affectedByGravity = false
        physics.isDynamic = false
        slashNode.physicsBody = physics
        
        
        addChild(slashNode)
        self.slashNode = slashNode
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            slashNode.removeFromParent()
        }
    }
    
    func applySlashAnimation() {
        marlinNode.removeAllActions()
        let slashAnimation = SKAction.animate(with: slashFrames, timePerFrame: 0.1, resize: false, restore: true)
        isSlashAnimationRunning = true
        marlinNode.run(slashAnimation) {
            self.marlinNode.removeAllActions()
            self.isSlashAnimationRunning = false
            self.applySwimmingAnimation(timePerFrame: self.currentTimePerFrame)
        }
    }
    
    func applyPlayerStickMove() {
        guard let controller = virtualController?.controller?.extendedGamepad else { return }
        self.stickInputX = CGFloat(controller.leftThumbstick.xAxis.value)
        self.stickInputY = CGFloat(controller.leftThumbstick.yAxis.value)
        let rotationAngle = atan2(stickInputY, stickInputX)
        let friction = 0.975
         
        playerVelocity.dx *= friction
        playerVelocity.dy *= friction
        
        if stickInputX != 0 || stickInputY != 0 {
            playerVelocity.dx += cos(rotationAngle) * acceleration
            playerVelocity.dy += sin(rotationAngle) * acceleration
            
            if playerVelocity.dx < 0 {
                marlinNode.yScale = -1
            } else {
                marlinNode.yScale = 1
            }
            
            if playerSpeed < 1 {
                let timePerFrame = 0.1
                if currentTimePerFrame != timePerFrame {
                    applySwimmingAnimation(timePerFrame: timePerFrame)
                    currentTimePerFrame = timePerFrame
                }
                bubbleNode.particleBirthRate = 5000
            } else {
                let timePerFrame = 0.01
                if currentTimePerFrame != timePerFrame {
                    applySwimmingAnimation(timePerFrame: timePerFrame)
                    currentTimePerFrame = timePerFrame
                }
                bubbleNode.particleBirthRate = 10000
            }
        } else {
            bubbleNode.particleBirthRate = 0
            let timePerFrame = 0.1
            if currentTimePerFrame != timePerFrame {
                applySwimmingAnimation(timePerFrame: timePerFrame)
                currentTimePerFrame = timePerFrame
            }
        }
        
        playerVelocity.dx = min(max(playerVelocity.dx, -maxSpeed), maxSpeed)
        playerVelocity.dy = min(max(playerVelocity.dy, -maxSpeed), maxSpeed)
        
        marlinNode.position.x += playerVelocity.dx
        marlinNode.position.y += playerVelocity.dy

//        // 회전 각도를 적용
        if stickInputX != 0 || stickInputY != 0 {
            marlinNode.zRotation = rotationAngle
        }
    }
    
    func setupCamera() {
        cameraNode.position = marlinNode.position
        let xRange = SKRange(lowerLimit: self.frame.width / 2, upperLimit: self.frame.width * 1.5)
        let yRange = SKRange(lowerLimit: self.frame.height / 2 - 1, upperLimit: self.frame.height / 2)
        let constraint = SKConstraint.positionX(xRange, y: yRange)
        cameraNode.constraints = [constraint]
        addChild(cameraNode)
        camera = cameraNode
    }
    
    func tutorial() {
        self.stun = true
        
        func applyMarlinMove() {
            let moveAnimation = SKAction.move(to: CGPoint(x: self.frame.width / 2, y: self.frame.height / 2), duration: 5)
            marlinNode.run(moveAnimation) {
//                self.createNet()
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    closeUpMarlin()
                }
            }
        }
        
        func closeUpMarlin() {
            let scaleAnimation = SKAction.scale(by: 0.5, duration: 2)
            
            cameraNode.run(scaleAnimation) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    angryMarlin() {
                        wideShotMarlin()
                    }
                }
            }
        }
        
        func angryMarlin(completion: @escaping () -> ()) {
            marlinNode.texture = SKTexture(imageNamed: "angryMarlin")
            completion()
        }
        
        func wideShotMarlin() {
            let wait = SKAction.wait(forDuration: 1)
            let reduceAnimation = SKAction.scale(by: 2, duration: 1)
            let sequence = SKAction.sequence([wait, reduceAnimation])
            
            cameraNode.run(sequence) {
                self.isPaused = true
                self.triggerNotification(tutorial: .dash)
                self.stun = false
                self.makeVirtualController()
            }
        }
        
        applyMarlinMove()
    }
    
    func triggerNotification(tutorial: TutorialState) {
        self.tutorialState = tutorial
    }
    
    func animateCamera() {
        let animate = SKAction.scale(by: 0.5, duration: 0.5)
        let wait = SKAction.wait(forDuration: 7)
        let animate2 = SKAction.scale(by: 2, duration: 3)
        let sequence = SKAction.sequence([animate, wait, animate2])
        cameraNode.run(sequence)
    }
    
    func updateMarlinPosition() {
        if marlinNode.position.x < minX {
            marlinNode.position.x = minX
        } else if marlinNode.position.x > maxX {
            marlinNode.position.x = maxX
        }
        
        if marlinNode.position.y < minY {
            marlinNode.position.y = minY
        } else if marlinNode.position.y > maxY {
            marlinNode.position.y = maxY
        }
    }
    
    func makeMarlin() {
        let marlinSize = CGSize(width: 75, height: 75)
        let physics = SKPhysicsBody(rectangleOf: CGSize(width: marlinSize.width / 10, height: marlinSize.height / 10))
        physics.categoryBitMask = PhysicsCategory.Marlin
        physics.contactTestBitMask = PhysicsCategory.TrawlingNet | PhysicsCategory.Line | PhysicsCategory.Corals
        physics.collisionBitMask = 0
        
        marlinNode = SKSpriteNode(imageNamed: "marlin_swimming_1")
        marlinNode.position = CGPoint(x: minX, y: self.frame.height / 2)
        marlinNode.size = marlinSize
        marlinNode.physicsBody = physics
        marlinNode.physicsBody?.isDynamic = true
        marlinNode.physicsBody?.affectedByGravity = false
        marlinNode.zPosition = 6
        marlinNode.xScale = -1
        marlinNode.anchorPoint = CGPoint(x: 0.3, y: 0.5)
        
        addChild(marlinNode)
        
        applySwimmingAnimation(timePerFrame: 0.01)
    }
    
    
    func createRandomMoveAction() -> SKAction {
        let randomMove = SKAction.move(to: CGPoint(x: CGFloat.random(in: minX...maxX), y: CGFloat.random(in: minY...maxY)), duration: CGFloat.random(in: 30...50))
        
        return randomMove
    }
    
    func addFishes() {
        for i in 1...200 {
            let randomFish = CGFloat.random(in: 1...4)
            let fishNode = SKSpriteNode(imageNamed: "fish_\(randomFish)")
            let fishSize = CGSize(width: 10, height: 8)
            let physics = SKPhysicsBody(rectangleOf: fishSize)
            let randomPosition = CGPoint(x: CGFloat.random(in: minX...maxX), y: CGFloat.random(in: minY...maxY))
            physics.affectedByGravity = false
            physics.isDynamic = false
            fishNode.physicsBody = physics
            fishNode.size = fishSize
            fishNode.position = randomPosition

            // Create random move action
            let repeatAction = SKAction.repeatForever(SKAction.sequence([
                self.createRandomMoveAction(),
                SKAction.run {
                    fishNode.run(self.createRandomMoveAction())
                }
            ]))
            repeatAction.timingMode = .easeInEaseOut
            
            fishNode.run(repeatAction)

            addChild(fishNode)
            fishes.append(fishNode)
        }
    }

    
    func applySwimmingAnimation(timePerFrame: CGFloat) {
        guard !isSlashAnimationActivate() else { return }
        let swimmingaAnimation = SKAction.animate(with: swimmingFrames, timePerFrame: timePerFrame, resize: false, restore: true)
        let reversedAnimation = swimmingaAnimation.reversed()
        // 애니메이션을 무한 반복하도록 설정합니다.
        let sequence = SKAction.sequence([swimmingaAnimation, reversedAnimation])
        let repeatAction = SKAction.repeatForever(sequence)
            
        // 물고기에 애니메이션을 적용합니다.
        marlinNode.run(repeatAction, withKey: "swimming")
    }
    
    func bubbleEmitter(position: CGPoint) {
        guard let bubbleImage = UIImage(named: "bubble") else { return }
        
        bubbleNode.particleTexture = SKTexture(image: bubbleImage)
        bubbleNode.particleBirthRate = 2500
        bubbleNode.particleLifetime = 1
        bubbleNode.particleScale = 0.03
        bubbleNode.particleScaleRange = 0.07
        bubbleNode.particleAlpha = 1
        bubbleNode.particleSpeed = 50
        bubbleNode.particleSpeedRange = 20
        bubbleNode.xAcceleration = 0
        bubbleNode.yAcceleration = 10
        bubbleNode.emissionAngle = CGFloat.pi * 3 / 4
        bubbleNode.emissionAngleRange = CGFloat.pi / 6
        bubbleNode.particlePositionRange = CGVector(dx: 1, dy: 1)
        bubbleNode.targetNode = self
        bubbleNode.position = position
        
        marlinNode.addChild(bubbleNode)
    }
    
    func createNet() {
        let netNode = SKSpriteNode(imageNamed: "InGameNet")
        let lineNode = SKSpriteNode(imageNamed: "InGameNet")
        let sandBubbleNode = SKEmitterNode()
        
        let xPositions: [CGFloat] = [self.frame.width * 2.6, -self.frame.width * 0.6]
        guard let randomXPosition = xPositions.randomElement() else { return }
        

        
        
        
        let width = self.frame.height * 1.21
        let height = self.frame.height
        netNode.size = CGSize(width: width, height: self.frame.height)
        lineNode.size = CGSize(width: width, height: self.frame.height)

        let netPath = CGMutablePath()
        let origin = CGPoint(x: width * 0.7, y: height * 0.375)
        netPath.move(to: origin)
        netPath.addLine(to: CGPoint(x: width * 0.7, y: height * 0.25))
        netPath.addLine(to: CGPoint(x: width * 0.137, y: height * 0.17))
        netPath.addLine(to: CGPoint(x: width * 0.137, y: height * 0.084))
        netPath.addLine(to: CGPoint(x: width * 0.72, y: height * 0.125))
        netPath.addLine(to: CGPoint(x: width * 0.72, y: 0))
        netPath.addLine(to: CGPoint(x: width * 0.03, y: 0))
        netPath.addLine(to: CGPoint(x: width * 0.03, y: height * 0.2))
        netPath.addLine(to: origin)
        
        
        let netPhysics = SKPhysicsBody(polygonFrom: netPath)
        
        let linePath = CGMutablePath()
        let lineOrigin = CGPoint(x: width * 0.7, y: height * 0.4)
        linePath.move(to: lineOrigin)
        linePath.addLine(to: CGPoint(x: width * 0.72, y: height * 0.33))
        linePath.addLine(to: CGPoint(x: width, y: height * 0.945))
        linePath.addLine(to: CGPoint(x: width * 0.948, y: height))
        linePath.addLine(to: lineOrigin)
        
        
        let linePhysics = SKPhysicsBody(polygonFrom: linePath)
        linePhysics.categoryBitMask = PhysicsCategory.Line
        linePhysics.contactTestBitMask = PhysicsCategory.Slash
        linePhysics.collisionBitMask = 0
        linePhysics.affectedByGravity = false
        linePhysics.isDynamic = true
        linePhysics.linearDamping = 10
        linePhysics.allowsRotation = false
        linePhysics.angularDamping = 10
        lineNode.physicsBody = linePhysics
        lineNode.anchorPoint = .zero
        
        netPhysics.categoryBitMask = PhysicsCategory.TrawlingNet
        netPhysics.contactTestBitMask = PhysicsCategory.Marlin
        netPhysics.collisionBitMask = 0
        
        netPhysics.affectedByGravity = false
        netPhysics.isDynamic = true
        
        netPhysics.isDynamic = true
        netPhysics.linearDamping = 10
        netPhysics.allowsRotation = false
        netPhysics.angularDamping = 10
        
        netNode.physicsBody = netPhysics
        netNode.anchorPoint = .zero
        
        netNode.position = CGPoint(x: randomXPosition, y: 1)
//        lineNode.position = netNode.position
        
        if randomXPosition > 0 {
            netNode.xScale = -1
//            lineNode.xScale = -1
        }
        netNode.zPosition = 10
        lineNode.zPosition = 10
        animateSandStorm()
        addChild(netNode)
        netNode.addChild(lineNode)
        
        netCount += 1
        animateNet()
        
        let co2IncrementAction = SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
               SKAction.run {
                   self.co2Concentration += 1
               }
           ]))
           self.run(co2IncrementAction, withKey: "CO2Increment_\(netCount)")
        
        func animateSandStorm() {
        guard let bubbleImage = UIImage(named: "sandBubble") else { return }
        
        sandBubbleNode.particleTexture = SKTexture(image: bubbleImage)
        sandBubbleNode.particleBirthRate = 60000
        sandBubbleNode.particleLifetime = 2
        sandBubbleNode.particleLifetimeRange = 2
        sandBubbleNode.particleScale = 0.1
        sandBubbleNode.particleScaleRange = 0.07
        sandBubbleNode.particleAlpha = 1
        sandBubbleNode.particleSpeed = 50
        sandBubbleNode.particleSpeedRange = 20
        sandBubbleNode.xAcceleration = 0
        sandBubbleNode.yAcceleration = 70
        sandBubbleNode.emissionAngle = CGFloat.pi
        sandBubbleNode.emissionAngleRange = CGFloat.pi / 4
        sandBubbleNode.particlePositionRange = CGVector(dx: 1200, dy: 100)
        sandBubbleNode.targetNode = self
        sandBubbleNode.particleZPosition = 11
        sandBubbleNode.position = CGPoint(x: 0, y: 0)
        
        netNode.addChild(sandBubbleNode)
    }
        
        func animateNet() {
            var arrivalX: CGFloat {
                if netNode.position.x > 0 {
                    return -self.frame.width * 0.76
                } else {
                    return self.frame.width * 2.5
                }
            }
            
            let move = SKAction.move(to: CGPoint(x: arrivalX, y: 0), duration: 30)

            let scaleAnimation = SKAction.scale(to: 1.05, duration: 3)
            let scaleAnimation2 = SKAction.scale(to: 0.95, duration: 3)
            let wait = SKAction.wait(forDuration: 5)
            let remove = SKAction.removeFromParent()
            
            let waitAndRemoveAnimation = SKAction.sequence([wait, remove])
            
            let sequenceAnimation = SKAction.sequence([scaleAnimation, scaleAnimation2])
            let repeatAnimation = SKAction.repeat(sequenceAnimation, count: 5)
            let groupAnimation = SKAction.group([move, repeatAnimation])
            
            
//            lineNode.run(move) {
//                lineNode.removeFromParent()
//                netNode.removeFromParent()
//                self.netCount -= 1
//            }
            netNode.run(move) {
                sandBubbleNode.particleBirthRate = 0
                sandBubbleNode.run(waitAndRemoveAnimation) {
                    netNode.removeFromParent()
                    lineNode.removeFromParent()
                    self.netCount -= 1
                }
                
                
            }
        
        }
    }
    
    
    
    
    
    
    func createBackground() {
        let firstBackgroundNode = SKSpriteNode(imageNamed: "gameBackground_1")
        let secondBackgroundNode = SKSpriteNode(imageNamed: "gameBackground_2")
        firstBackgroundNode.anchorPoint = .zero
        firstBackgroundNode.position = .zero
        firstBackgroundNode.size  = CGSize(width: self.frame.width, height: self.frame.height)

        secondBackgroundNode.anchorPoint = .zero
        secondBackgroundNode.position = CGPoint(x: firstBackgroundNode.position.x + firstBackgroundNode.size.width, y: firstBackgroundNode.position.y)
        secondBackgroundNode.size = CGSize(width: self.frame.width, height: self.frame.height)
        addChild(firstBackgroundNode)
        addChild(secondBackgroundNode)

        self.firstBackgroundNode = firstBackgroundNode
        self.secondBackgroundNode = secondBackgroundNode
        backgroundWidth = firstBackgroundNode.size.width
    }
    
    private func beInfiniteNodes(firstNode: SKSpriteNode, secondNode: SKSpriteNode) {
        if firstNode.position.x <= -firstNode.size.width {
            firstNode.position.x = secondNode.position.x + secondNode.size.width
            
        }
        
        if secondNode.position.x <= -secondNode.size.width {
            secondNode.position.x = firstNode.position.x + firstNode.size.width
          }
    }
    
    func createFloor() {
        let firstFloorNode = SKSpriteNode(imageNamed: "sand_1")
        let secondFloorNode = SKSpriteNode(imageNamed: "sand_2")
        let nodeSize = CGSize(width: self.frame.width, height: self.frame.height * 0.23)
        let firstFloorPhysics = SKPhysicsBody(rectangleOf: nodeSize)
        let secondFloorPhysics = SKPhysicsBody(rectangleOf: nodeSize)
        
        firstFloorPhysics.affectedByGravity = false
        firstFloorPhysics.isDynamic = false
        
        firstFloorNode.size = nodeSize
        firstFloorNode.anchorPoint = .zero
        firstFloorNode.position = .zero
        firstFloorNode.physicsBody = firstFloorPhysics
        firstFloorNode.zPosition = 3
        
        
        secondFloorPhysics.affectedByGravity = false
        secondFloorPhysics.isDynamic = false
        
        secondFloorNode.size = nodeSize
        secondFloorNode.anchorPoint = .zero
        secondFloorNode.position = CGPoint(x: firstFloorNode.position.x + firstFloorNode.size.width, y: firstFloorNode.position.y)
        secondFloorNode.physicsBody = secondFloorPhysics
        secondFloorNode.zPosition = 3
        
        let coralsNode = createCorals(name: "test")
        coralsNode.anchorPoint = CGPoint(x: 0, y: 0)
        coralsNode.position = CGPoint(x: 0, y: 0)
        let secondCoralsNode = createCorals(name: "test")
        secondCoralsNode.anchorPoint = CGPoint(x: 0, y: 0)
        secondCoralsNode.position = CGPoint(x: 0, y: 0)
        secondCoralsNode.xScale = 1
        firstFloorNode.addChild(coralsNode)
        secondFloorNode.addChild(secondCoralsNode)
        self.coralNodes.append(coralsNode)
        self.coralNodes.append(secondCoralsNode)
        
        addChild(firstFloorNode)
        addChild(secondFloorNode)
        
        self.firstFloorNode = firstFloorNode
        self.secondFloorNode = secondFloorNode
    }
    
    func createCorals(name: String) -> SKSpriteNode {
        let coralsNode = SKSpriteNode(imageNamed: name)
        let nodeSize = CGSize(width: self.frame.width, height: 300)
        coralsNode.size = nodeSize
        let physics = SKPhysicsBody(rectangleOf: nodeSize)
        physics.categoryBitMask = PhysicsCategory.Corals
        physics.contactTestBitMask = PhysicsCategory.Marlin
        physics.collisionBitMask = 0
        physics.affectedByGravity = false
        physics.isDynamic = false
        coralsNode.anchorPoint = CGPoint(x: 0.5, y: 0)
        
        coralsNode.zPosition = 4
        coralsNode.physicsBody = physics
        
        return coralsNode
    }
    
    func bleachedCorals() {
        let fadeOut = SKAction.fadeIn(withDuration: 10)
        let fadeIn = SKAction.fadeIn(withDuration: 10)
        
        let firstBleachedCoral = createCorals(name: "bleached_corals")
        firstBleachedCoral.anchorPoint = CGPoint(x: 0, y: 0)
        firstBleachedCoral.position = CGPoint(x: 0, y: 0)
        firstBleachedCoral.alpha = 0
        
        let secondBleachedCoral = createCorals(name: "bleached_corals")
        secondBleachedCoral.anchorPoint = CGPoint(x: 0, y: 0)
        secondBleachedCoral.position = CGPoint(x: 0, y: 0)
        secondBleachedCoral.xScale = 1
        secondBleachedCoral.alpha = 0
        
        let fadeInAction = SKAction.fadeIn(withDuration: 10)
         firstBleachedCoral.run(fadeInAction)
         secondBleachedCoral.run(fadeInAction)
        
        for node in coralNodes {
            node.run(fadeOut) {
                node.removeFromParent()
            }
        }
        
        firstBleachedCoral.physicsBody?.categoryBitMask = 0
        secondBleachedCoral.physicsBody?.categoryBitMask = 0
        
        self.firstFloorNode.addChild(firstBleachedCoral)
        self.secondFloorNode.addChild(secondBleachedCoral)
    }
    
    func removeAllFishes() {
        for fish in fishes {
            fish.removeFromParent()
        }
        for boid in backgroundBoids {
            boid.removeFromParent()
        }
        
        for boid in backgroundBoids2 {
            boid.removeFromParent()
        }
    }
}


class BoidNode: SKSpriteNode {
    var velocity: CGVector = .zero
    
    func update(with boids: [BoidNode], bounds: CGRect, padding: CGFloat, maxSpeed: CGFloat) {
        applyRules(with: boids)
        applyBounds(bounds: bounds, padding: padding)
        limitVelocity(maxSpeed: maxSpeed)
        
        position.x += velocity.dx
        position.y += velocity.dy
    }
    
    private func applyRules(with boids: [BoidNode]) {
        let separation = calculateSeparation(from: boids)
        velocity.dx += separation.dx
        velocity.dy += separation.dy
        
        let alignment = calculateAlignment(from: boids)
        velocity.dx += alignment.dx
        velocity.dy += alignment.dy
        
        let cohesion = calculateCohesion(from: boids)
        velocity.dx += cohesion.dx
        velocity.dy += cohesion.dy
    }
    
    private func calculateSeparation(from boids: [BoidNode]) -> CGVector {
        var separation = CGVector.zero
        
        for otherBoid in boids {
            let distance = distance(to: otherBoid.position)
            if distance > 0 && distance < 20 {
                separation.dx += (position.x - otherBoid.position.x) / distance
                separation.dy += (position.y - otherBoid.position.y) / distance
            }
        }
        
        return separation
    }
    
    private func calculateAlignment(from boids: [BoidNode]) -> CGVector {
        var alignment = CGVector.zero
        
        for otherBoid in boids {
            let distance = distance(to: otherBoid.position)
            if distance > 0 && distance < 20 {
                alignment.dx += otherBoid.velocity.dx
                alignment.dy += otherBoid.velocity.dy
            }
        }
        
        return alignment
    }
    
    private func calculateCohesion(from boids: [BoidNode]) -> CGVector {
        var cohesion = CGVector.zero
        var centerOfMass = CGPoint.zero
        
        for otherBoid in boids {
            centerOfMass.x += otherBoid.position.x
            centerOfMass.y += otherBoid.position.y
        }
        
        centerOfMass.x /= CGFloat(boids.count)
        centerOfMass.y /= CGFloat(boids.count)
        
        cohesion.dx = (centerOfMass.x - position.x) / 200
        cohesion.dy = (centerOfMass.y - position.y) / 200
        
        return cohesion
    }
    
    private func applyBounds(bounds: CGRect, padding: CGFloat) {
        if position.x < bounds.minX + padding {
            velocity.dx += 2
        }
        if position.x > bounds.maxX - padding {
            velocity.dx -= 2
        }
        if position.y < bounds.minY + padding {
            velocity.dy += 2
        }
        if position.y > bounds.maxY - padding {
            velocity.dy -= 2
        }
    }
    
    private func limitVelocity(maxSpeed: CGFloat) {
        let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
        if speed > maxSpeed {
            let factor = maxSpeed / speed
            velocity.dx *= factor
            velocity.dy *= factor
        }
    }
    
    private func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(position.x - point.x, 2) + pow(position.y - point.y, 2))
    }
}

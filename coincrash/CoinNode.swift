

import Foundation
import SceneKit
import ARKit
import GLTFSceneKit

class CoinNode: SCNNode {
    
    private var rotationAnimation: SCNAction?
    private var caught: Bool = false
    weak var sceneView: ARSCNView?
    private var originalModelNode: SCNNode
    
    init(modelNode: SCNNode, sceneView: ARSCNView) {
        self.sceneView = sceneView
        self.originalModelNode = modelNode
        super.init()
        
        self.position = modelNode.position
        self.rotation = modelNode.rotation
        self.scale = modelNode.scale
        self.transform = modelNode.transform
        self.name = modelNode.name
        
        for childNode in modelNode.childNodes {
            let copiedChild = childNode.clone()
            addChildNode(copiedChild)
        }
        
        if let geometry = modelNode.geometry {
            self.geometry = geometry
        }
        
        for key in modelNode.actionKeys {
            if let action = modelNode.action(forKey: key) {
                runAction(action, forKey: key)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func catchCoin() {
        guard !caught else { return }
        caught = true
        
        if let rotation = rotationAnimation {
            removeAction(forKey: "rotation")
        }
        
        DispatchQueue.main.async {
            self.startFloatAwayAnimation()
            self.spawnStars()
        }
    }
    
    private func startRotation() {
        let rotateAction = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 3.0)
        let repeatForever = SCNAction.repeatForever(rotateAction)
        rotationAnimation = repeatForever
        runAction(repeatForever, forKey: "rotation")
    }
    
    private func startFloatAwayAnimation() {
        let duration: TimeInterval = 2.0
        let frameRate: TimeInterval = 1.0 / 60.0
        let totalFrames = Int(duration / frameRate)
        
        var currentFrame = 0
        
        let timer = Timer.scheduledTimer(withTimeInterval: frameRate, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            currentFrame += 1
            let progress = Float(currentFrame) / Float(totalFrames)
            
            self.position = SCNVector3(
                self.position.x,
                self.position.y + 0.01,
                self.position.z
            )
            
            let newScale = self.scale.x * 0.95
            self.scale = SCNVector3(newScale, newScale, newScale)
            
            if currentFrame >= totalFrames {
                timer.invalidate()
                self.removeFromParentNode()
            }
        }
    }
    
    private func spawnStars() {
        guard let sceneView = sceneView else { return }
        
        for _ in 0..<18 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.0...0.3)) {
                self.createSingleStar()
            }
        }
    }
    
    private func createSingleStar() {
        guard let sceneView = sceneView else { return }
        
        if let starURL = Bundle.main.url(forResource: "star", withExtension: "glb") {
            do {
                let sceneSource = GLTFSceneSource(url: starURL)
                let scene = try sceneSource.scene(options: [
                    .checkConsistency: true,
                    .convertUnitsToMeters: true,
                    .convertToYUp: true
                ])
                
                if let firstChild = scene.rootNode.childNodes.first {
                    let starModel = firstChild.clone()
                    let spawnPosition = SCNVector3(
                        worldPosition.x + StarNode.randomFloat(min: -0.3, max: 0.3),
                        worldPosition.y + 2.0,
                        worldPosition.z + StarNode.randomFloat(min: -0.3, max: 0.3)
                    )
                    
                    let starNode = StarNode(modelNode: starModel, spawnPosition: spawnPosition)
                    starNode.castsShadow = false
                    sceneView.scene.rootNode.addChildNode(starNode)
                }
            } catch {
                createGeometricStar()
            }
        } else {
            createGeometricStar()
        }
    }
    
    private func createGeometricStar() {
        guard let sceneView = sceneView else { return }
        
        let starGeometry = createStarGeometry()
        let starModel = SCNNode(geometry: starGeometry)
        
        let spawnPosition = SCNVector3(
            worldPosition.x + StarNode.randomFloat(min: -0.3, max: 0.3),
            worldPosition.y + 2.0,
            worldPosition.z + StarNode.randomFloat(min: -0.3, max: 0.3)
        )
        
        let starNode = StarNode(modelNode: starModel, spawnPosition: spawnPosition)
        starNode.castsShadow = false
        sceneView.scene.rootNode.addChildNode(starNode)
    }
    
    private func createStarGeometry() -> SCNGeometry {
        let centerBox = SCNBox(width: 0.02, height: 0.02, length: 0.002, chamferRadius: 0)
        
        let material = SCNMaterial()
        let starColors = [UIColor.systemYellow, UIColor.white]
        let selectedColor = starColors.randomElement() ?? UIColor.systemYellow
        
        material.diffuse.contents = selectedColor
        material.specular.contents = UIColor.white
        material.emission.contents = selectedColor.withAlphaComponent(0.3)
        material.metalness.contents = 0.8
        material.roughness.contents = 0.2
        
        centerBox.materials = [material]
        return centerBox
    }
}

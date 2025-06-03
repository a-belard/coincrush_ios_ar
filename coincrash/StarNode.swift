import Foundation
import SceneKit
import ARKit
import GLTFSceneKit

class StarNode: SCNNode {

    private var xVelocity: Float
    private var yVelocity: Float
    private var zVelocity: Float
    private var rotationSpeed: Float
    private var currentRotation: Float = 0
    
    init(modelNode: SCNNode, spawnPosition: SCNVector3) {
        self.xVelocity = 0.0 
        self.yVelocity = StarNode.randomFloat(min: -0.01, max: -0.005)
        self.zVelocity = 0.0
        self.rotationSpeed = StarNode.randomFloat(min: -1, max: 1)
        
        super.init()
        
        addChildNode(modelNode)
        
        position = spawnPosition
        scale = SCNVector3(0.0025, 0.0025, 0.0025)
        
        startFallingAnimation()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func randomFloat(min: Float, max: Float) -> Float {
        return Float.random(in: min...max)
    }
    
    private func startFallingAnimation() {
        let duration: TimeInterval = 3.0 
        let frameRate: TimeInterval = 1.0 / 50.0
        let totalFrames = Int(duration / frameRate)
        
        var currentFrame = 0
        
        let timer = Timer.scheduledTimer(withTimeInterval: frameRate, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            currentFrame += 1
            let progress = Float(currentFrame) / Float(totalFrames)
            
            self.yVelocity -= 0.0025
            
            self.position = SCNVector3(
                self.position.x + self.xVelocity,
                self.position.y + self.yVelocity,
                self.position.z + self.zVelocity
            )
            
            self.currentRotation += self.rotationSpeed
            self.eulerAngles = SCNVector3(
                self.currentRotation * .pi / 180,
                self.currentRotation * .pi / 180,
                self.currentRotation * .pi / 180
            )
            
            if progress > 0.7 {
                let fadeProgress = (progress - 0.7) / 0.3
                let newScale = 0.01 * (1 - fadeProgress)
                self.scale = SCNVector3(newScale, newScale, newScale)
            }
            
            if currentFrame >= totalFrames {
                timer.invalidate()
                self.removeFromParentNode()
            }
        }
    }
}

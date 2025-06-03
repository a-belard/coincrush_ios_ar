import Foundation
import ARKit
import SceneKit
import GLTFSceneKit

class StarEffectManager {
    
    weak var sceneView: ARSCNView?
    
    init(sceneView: ARSCNView) {
        self.sceneView = sceneView
    }
    
    func createCatchEffect(at position: SCNVector3) {
        guard let sceneView = sceneView else { return }
        
        
        createMultipleStarEffect(at: position)
    }
    
    func createMultipleStarEffect(at position: SCNVector3) {
        guard let sceneView = sceneView else { return }
        
        for _ in 0..<100 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.0...0.2)) {
                self.createSingleEnhancedStar(at: position)
            }
        }
    }
    
    private func createSingleEnhancedStar(at position: SCNVector3) {
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
                        position.x + Float.random(in: -0.3...0.3),
                        position.y + 2.0,
                        position.z + Float.random(in: 0.3...0.4)
                    )
                    
                    let starNode = StarNode(modelNode: starModel, spawnPosition: spawnPosition)
                    starNode.castsShadow = false
                    sceneView.scene.rootNode.addChildNode(starNode)
                }
            } catch {
                print("DEBUG: Error loading star model: \(error)")
                createGeometricStarAt(position: position)
            }
        } else {
            createGeometricStarAt(position: position)
        }
    }
    
    private func createGeometricStarAt(position: SCNVector3) {
        guard let sceneView = sceneView else { return }
        
        let starGeometry = createStarGeometry()
        let starModel = SCNNode(geometry: starGeometry)
        
        let spawnPosition = SCNVector3(
            position.x + Float.random(in: -0.3...0.3),
            position.y + 2.0,
            position.z + Float.random(in: -0.3...0.3)
        )
        
        let starNode = StarNode(modelNode: starModel, spawnPosition: spawnPosition)
        starNode.castsShadow = false
        sceneView.scene.rootNode.addChildNode(starNode)
    }
    
    private func createStarGeometry() -> SCNGeometry {
        let centerBox = SCNBox(width: 0.02, height: 0.02, length: 0.002, chamferRadius: 0)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.systemYellow
        material.specular.contents = UIColor.white
        material.emission.contents = UIColor.systemYellow.withAlphaComponent(0.3)
        material.metalness.contents = 0.8
        material.roughness.contents = 0.2
        
        centerBox.materials = [material]
        return centerBox
    }
    
    private func createVortexConfettiEffect(using scene: SCNScene, at position: SCNVector3) {
        guard let sceneView = sceneView else { return }
        
        let starNode = SCNNode()
        
        if !scene.rootNode.childNodes.isEmpty {
            for childNode in scene.rootNode.childNodes {
                let clonedChild = childNode.clone()
                preserveOriginalMaterials(node: clonedChild)
                starNode.addChildNode(clonedChild)
            }
        } else {
            let clonedRoot = scene.rootNode.clone()
            preserveOriginalMaterials(node: clonedRoot)
            starNode.addChildNode(clonedRoot)
        }
        
        let scale: Float = 0.03
        starNode.scale = SCNVector3(scale, scale, scale)
        
        starNode.position = position
        print("DEBUG: Star positioned at: \(position)")
        
        starNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        starNode.physicsBody?.mass = 0.1
        starNode.physicsBody?.damping = 0.2
        starNode.physicsBody?.angularDamping = 0.5
        starNode.physicsBody?.isAffectedByGravity = false
        starNode.physicsBody?.restitution = 0.3
        
        starNode.physicsBody?.velocity = SCNVector3(0, 0, 0)
        starNode.physicsBody?.angularVelocity = SCNVector4(0, 0, 0, 0)
        
        sceneView.scene.rootNode.addChildNode(starNode)
        
        let worldGravity = SCNVector3(0, -9.8, 0)
        starNode.physicsBody?.applyForce(worldGravity, asImpulse: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            starNode.removeFromParentNode()
        }
    }
    
    private func createGeometricVortexConfettiEffect(at position: SCNVector3) {
        guard let sceneView = sceneView else { return }
        
        print("DEBUG: Creating single falling star effect")
        
        let starNode = createGeometricStar()
        
        let scale: Float = 0.3
        starNode.scale = SCNVector3(scale, scale, scale)
        
        starNode.position = position
        print("DEBUG: Geometric star positioned at: \(position)")
        
        starNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        starNode.physicsBody?.mass = 0.1
        starNode.physicsBody?.damping = 0.2
        starNode.physicsBody?.angularDamping = 0.5
        starNode.physicsBody?.isAffectedByGravity = false
        starNode.physicsBody?.restitution = 0.3
        
        starNode.physicsBody?.velocity = SCNVector3(0, 0, 0)
        starNode.physicsBody?.angularVelocity = SCNVector4(0, 0, 0, 0)
        
        sceneView.scene.rootNode.addChildNode(starNode)
        
        let worldGravity = SCNVector3(0, -9.8, 0)
        starNode.physicsBody?.applyForce(worldGravity, asImpulse: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            starNode.removeFromParentNode()
        }
        
        print("DEBUG: Created single falling star")
    }
    
    private func createGeometricStar() -> SCNNode {
        let starNode = SCNNode()
        
        let centerBox = SCNBox(width: 0.2, height: 0.2, length: 0.02, chamferRadius: 0)
        let centerNode = SCNNode(geometry: centerBox)
        
        let armLength: CGFloat = 0.6
        let armWidth: CGFloat = 0.1
        let armThickness: CGFloat = 0.02
        
        let horizontalArm = SCNBox(width: armLength, height: armWidth, length: armThickness, chamferRadius: 0)
        let horizontalNode = SCNNode(geometry: horizontalArm)
        
        let verticalArm = SCNBox(width: armWidth, height: armLength, length: armThickness, chamferRadius: 0)
        let verticalNode = SCNNode(geometry: verticalArm)
        
        let starMaterial = SCNMaterial()
        starMaterial.diffuse.contents = UIColor.systemYellow
        starMaterial.specular.contents = UIColor.white
        starMaterial.emission.contents = UIColor.systemYellow.withAlphaComponent(0.3)
        starMaterial.metalness.contents = 0.8
        starMaterial.roughness.contents = 0.2
        
        centerBox.materials = [starMaterial]
        horizontalArm.materials = [starMaterial]
        verticalArm.materials = [starMaterial]
        
        starNode.addChildNode(centerNode)
        starNode.addChildNode(horizontalNode)
        starNode.addChildNode(verticalNode)
        
        return starNode
    }
    
    private func createFallbackCatchEffect(at position: SCNVector3) {
        guard let sceneView = sceneView else { return }
        
        let catchParticleSystem = SCNParticleSystem()
        catchParticleSystem.birthRate = 100
        catchParticleSystem.particleLifeSpan = 1.0
        catchParticleSystem.emissionDuration = 0.3
        catchParticleSystem.spreadingAngle = 90
        catchParticleSystem.particleSize = 0.005
        catchParticleSystem.particleColor = UIColor.systemYellow
        catchParticleSystem.particleVelocity = 0.5
        catchParticleSystem.particleVelocityVariation = 0.3
        
        let effectNode = SCNNode()
        effectNode.position = position
        effectNode.addParticleSystem(catchParticleSystem)
        sceneView.scene.rootNode.addChildNode(effectNode)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            effectNode.removeFromParentNode()
        }
    }
    
    private func preserveOriginalMaterials(node: SCNNode) {
        for childNode in node.childNodes {
            preserveOriginalMaterials(node: childNode)
        }
        
        if let geometry = node.geometry {
            print("Preserving materials for node: \(node.name ?? "unnamed")")
            print("Material count: \(geometry.materials.count)")
            
            for (index, material) in geometry.materials.enumerated() {
                print("Material \(index): diffuse = \(material.diffuse.contents ?? "nil")")
                
                material.lightingModel = .physicallyBased
                
                if material.diffuse.contents == nil {
                    material.diffuse.contents = UIColor.white
                }
                
                if material.specular.contents == nil {
                    material.specular.contents = UIColor.white
                }
                
                if material.metalness.contents == nil {
                    material.metalness.contents = 0.1
                }
                if material.roughness.contents == nil {
                    material.roughness.contents = 0.3
                }
                
                material.emission.intensity = 0.1
                
                material.isDoubleSided = true
            }
        }
    }
}
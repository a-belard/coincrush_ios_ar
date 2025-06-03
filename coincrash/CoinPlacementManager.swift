//
//  CoinPlacementManager.swift
//  coincrash
//
//

import Foundation
import ARKit
import SceneKit
import CoreLocation
import GLTFSceneKit

protocol CoinPlacementManagerDelegate: AnyObject {
    func coinPlacementManager(_ manager: CoinPlacementManager, didPlaceCoin coinID: UUID, at position: simd_float3)
    func coinPlacementManager(_ manager: CoinPlacementManager, didRemoveCoin coinID: UUID)
    func coinPlacementManagerDidFailToFindSurface(_ manager: CoinPlacementManager)
    func coinPlacementManager(_ manager: CoinPlacementManager, didDetectCoinInRange coin: SCNNode, distance: Float)
    func coinPlacementManager(_ manager: CoinPlacementManager, didLoseCoinInRange coin: SCNNode)
    func coinPlacementManager(_ manager: CoinPlacementManager, didCatchCoin coinID: UUID, at position: simd_float3)
}

class CoinPlacementManager {
    
    weak var delegate: CoinPlacementManagerDelegate?
    private let coinManager = CoinManager()
    private let worldMapManager = WorldMapManager()
    private var starEffectManager: StarEffectManager?
    
    weak var sceneView: ARSCNView?
    private var currentMode: ARObjectType = .indoor
    
    private(set) var coinPositions = [UUID: simd_float3]()
    
    private var coinsInRange: Set<String> = []
    private let catchDistance: Float = 1.0
    private let catchAngle: Float = 45.0
    private var proximityCheckTimer: Timer?
    
    init(sceneView: ARSCNView, delegate: CoinPlacementManagerDelegate? = nil) {
        self.sceneView = sceneView
        self.delegate = delegate
        self.starEffectManager = StarEffectManager(sceneView: sceneView)
        startProximityChecking()
    }
    
    deinit {
        stopProximityChecking()
    }
    
    func setCurrentMode(_ mode: ARObjectType) {
        currentMode = mode
    }
    
    func setCoinPositions(_ positions: [UUID: simd_float3]) {
        coinPositions = positions
    }
    
    private func saveCoinPositions() {
        let (worldMap, _) = worldMapManager.loadWorldMapAndPositions()
        if let map = worldMap {
            worldMapManager.saveWorldMapAndPositions(map, coinPositions: coinPositions)
            print("Saved updated coin positions to persistent storage: \(coinPositions.count) coins")
        } else {
            print("Warning: Could not load world map for saving coin positions")
        }
    }
    
    func ensureProximityCheckingIsActive() {
        if proximityCheckTimer == nil || !(proximityCheckTimer?.isValid ?? false) {
            print("DEBUG: Restarting proximity checking")
            startProximityChecking()
        }
    }
    
    func handleTap(at location: CGPoint) {
        guard let sceneView = sceneView else { return }
        
        var hitTestResults: [ARHitTestResult] = []
        
        if currentMode == .indoor {
            hitTestResults = sceneView.hitTest(location, types: [.existingPlaneUsingExtent, .existingPlane, .featurePoint])
        } else {
            hitTestResults = sceneView.hitTest(location, types: [.featurePoint, .estimatedHorizontalPlane])
        }
        
        if let hitResult = hitTestResults.first {
            placeObject(at: hitResult)
        } else {
            delegate?.coinPlacementManagerDidFailToFindSurface(self)
        }
    }
    
    func removeCoinFromScene(with coinID: UUID) {
        guard let sceneView = sceneView else { return }
        
        if let anchorNode = sceneView.scene.rootNode.childNode(withName: "anchor_\(coinID.uuidString)", recursively: true) {
            anchorNode.removeFromParentNode()
            coinPositions.removeValue(forKey: coinID)
            worldMapManager.removeGPSLocation(for: coinID)
            
            saveCoinPositions()
            
            delegate?.coinPlacementManager(self, didRemoveCoin: coinID)
            print("Removed coin \(coinID) from AR scene")
        } else if let coinNode = sceneView.scene.rootNode.childNode(withName: coinID.uuidString, recursively: true) {
            coinNode.removeFromParentNode()
            coinPositions.removeValue(forKey: coinID)
            worldMapManager.removeGPSLocation(for: coinID)
            
            saveCoinPositions()
            
            delegate?.coinPlacementManager(self, didRemoveCoin: coinID)
            print("Removed coin \(coinID) from AR scene (fallback)")
        }
    }
    
    func restoreSavedCoins() {
        guard let sceneView = sceneView, !coinPositions.isEmpty else {
            print("No coins to restore")
            return
        }
        
        var restoredCount = 0
        
        for (coinID, position) in coinPositions {
            if sceneView.scene.rootNode.childNode(withName: coinID.uuidString, recursively: true) != nil {
                continue
            }
            
            let coinNode = coinManager.createCoinNode()
            coinNode.position = SCNVector3(position.x, position.y, position.z)
            coinNode.name = coinID.uuidString
            
            sceneView.scene.rootNode.addChildNode(coinNode)
            restoredCount += 1
            
        }
        
        if restoredCount > 0 {
            ensureProximityCheckingIsActive()
        }
    }
    
    func saveCoinLocation(coinID: UUID, gpsLocation: CLLocation) {
        worldMapManager.saveCoinLocation(coinID: coinID, gpsLocation: gpsLocation)
        print("Saved coin with GPS: \(gpsLocation.coordinate.latitude), \(gpsLocation.coordinate.longitude)")
    }
    
    func burstCoin(_ node: SCNNode) {
        guard let sceneView = sceneView else { return }
        
        let coinPosition = node.presentation.position
        var coinSize: CGFloat = 0.05
        if let cylinder = node.geometry as? SCNCylinder {
            coinSize = cylinder.radius
        }
        
        node.removeAllActions()
        
        let explosionParticleSystem = SCNParticleSystem()
        
        explosionParticleSystem.birthRate = 500
        explosionParticleSystem.particleLifeSpan = 0.75
        explosionParticleSystem.emissionDuration = 0.1
        explosionParticleSystem.spreadingAngle = 180
        explosionParticleSystem.particleSize = 0.003
        
        let blueColor = UIColor(red: 0.15, green: 0.35, blue: 0.8, alpha: 1.0)
        let goldColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
        
        if Bool.random() {
            explosionParticleSystem.particleColor = blueColor
        } else {
            explosionParticleSystem.particleColor = goldColor
        }
        
        explosionParticleSystem.particleColorVariation = SCNVector4(0.1, 0.1, 0, 0)
        
        explosionParticleSystem.particleVelocity = 0.5
        explosionParticleSystem.particleVelocityVariation = 0.2
        explosionParticleSystem.acceleration = SCNVector3(0, -0.2, 0)
        
        explosionParticleSystem.loops = false
        
        let particleNode = SCNNode()
        particleNode.position = coinPosition
        sceneView.scene.rootNode.addChildNode(particleNode)
        
        particleNode.addParticleSystem(explosionParticleSystem)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + explosionParticleSystem.particleLifeSpan + explosionParticleSystem.emissionDuration) {
            particleNode.removeFromParentNode()
        }
        
        createCoinFragments(at: coinPosition, with: coinSize)
        
        if let nodeName = node.name, let coinID = UUID(uuidString: nodeName) {
            coinPositions.removeValue(forKey: coinID)
            coinsInRange.remove(coinID.uuidString)
            
            worldMapManager.removeGPSLocation(for: coinID)
            
            saveCoinPositions()
            
            delegate?.coinPlacementManager(self, didRemoveCoin: coinID)
            
            print("Burst coin \(coinID) and cleaned up tracking data")
        }
        
        node.removeFromParentNode()
    }
    
    private func placeObject(at hitResult: ARHitTestResult) {
        guard let sceneView = sceneView else { return }
        
        let anchor = ARAnchor(transform: hitResult.worldTransform)
        
        sceneView.session.add(anchor: anchor)
        
        let coinID = UUID()
        
        let position = simd_float3(hitResult.worldTransform.columns.3.x, 
                                 hitResult.worldTransform.columns.3.y, 
                                 hitResult.worldTransform.columns.3.z)
        coinPositions[coinID] = position
        
        let objectNode = coinManager.createCoinNode()
        objectNode.name = coinID.uuidString
        
        let anchorNode = SCNNode()
        anchorNode.name = "anchor_\(coinID.uuidString)"
        anchorNode.simdTransform = hitResult.worldTransform
        
        anchorNode.addChildNode(objectNode)
        
        sceneView.scene.rootNode.addChildNode(anchorNode)
        
        print("Placed coin \(coinID) at position \(position) with anchor")
        
        ensureProximityCheckingIsActive()
        
        delegate?.coinPlacementManager(self, didPlaceCoin: coinID, at: position)
    }
    
    private func createCoinFragments(at position: SCNVector3, with size: CGFloat) {
        guard let sceneView = sceneView else { return }
        
        let blueColor = UIColor(red: 0.15, green: 0.35, blue: 0.8, alpha: 1.0)
        let goldColor = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
        let whiteColor = UIColor.white
        
        let fragmentCount = 15
        
        for i in 0..<fragmentCount {
            var geometry: SCNGeometry
            let geometryType = i % 3
            
            switch geometryType {
            case 0:
                let fragmentRadius = size * CGFloat.random(in: 0.15...0.3)
                let fragmentHeight = 0.01 * CGFloat.random(in: 0.5...1.0)
                geometry = SCNCylinder(radius: fragmentRadius, height: fragmentHeight)
            case 1:
                let fragmentSize = size * CGFloat.random(in: 0.1...0.25)
                geometry = SCNBox(width: fragmentSize, height: 0.01, length: fragmentSize, chamferRadius: 0)
            default:
                let fragmentRadius = size * CGFloat.random(in: 0.05...0.15)
                geometry = SCNSphere(radius: fragmentRadius)
            }
            
            let material = SCNMaterial()
            
            switch i % 5 {
            case 0, 1, 2:
                material.diffuse.contents = blueColor
            case 3:
                material.diffuse.contents = goldColor
            default:
                material.diffuse.contents = whiteColor
            }
            
            material.specular.contents = UIColor.white
            material.metalness.contents = 0.8
            material.roughness.contents = 0.2
            geometry.materials = [material]
            
            let fragmentNode = SCNNode(geometry: geometry)
            fragmentNode.position = position
            
            fragmentNode.position.x += Float.random(in: -0.02...0.02)
            fragmentNode.position.y += Float.random(in: -0.02...0.02)
            fragmentNode.position.z += Float.random(in: -0.02...0.02)
            
            let randomDirection = SCNVector3(
                Float.random(in: -1...1),
                Float.random(in: -1...1),
                Float.random(in: -1...1)
            )
            
            fragmentNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
            fragmentNode.physicsBody?.applyForce(
                SCNVector3(
                    randomDirection.x * 0.5,
                    randomDirection.y * 0.5,
                    randomDirection.z * 0.5
                ),
                asImpulse: true
            )
            
            fragmentNode.physicsBody?.applyTorque(
                SCNVector4(
                    Float.random(in: -1...1),
                    Float.random(in: -1...1),
                    Float.random(in: -1...1),
                    Float.random(in: 0.1...0.5)
                ),
                asImpulse: true
            )
            
            sceneView.scene.rootNode.addChildNode(fragmentNode)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                fragmentNode.removeFromParentNode()
            }
        }
    }
    
    func startProximityChecking() {
        proximityCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkCoinProximity()
        }
    }
    
    func stopProximityChecking() {
        proximityCheckTimer?.invalidate()
        proximityCheckTimer = nil
    }
    
    private func checkCoinProximity() {
        guard let sceneView = sceneView,
              let currentFrame = sceneView.session.currentFrame else {
            print("DEBUG: No scene view or current frame available")
            return
        }
        
        let cameraTransform = currentFrame.camera.transform
        let cameraPosition = simd_float3(cameraTransform.columns.3.x, cameraTransform.columns.3.y, cameraTransform.columns.3.z)
        let cameraForward = -simd_float3(cameraTransform.columns.2.x, cameraTransform.columns.2.y, cameraTransform.columns.2.z)
        
        // Find all coin nodes in the scene
        let coinNodes = sceneView.scene.rootNode.childNodes.filter { node in
            guard let nodeName = node.name,
                  let nodeUUID = UUID(uuidString: nodeName) else { return false }
            return coinPositions.keys.contains(nodeUUID)
        }
        
        
        var currentlyInRange: Set<String> = []
        
        for coinNode in coinNodes {
            guard let coinName = coinNode.name else { continue }
            
            let coinPosition = simd_float3(coinNode.worldPosition.x, coinNode.worldPosition.y, coinNode.worldPosition.z)
            let distance = simd_length(coinPosition - cameraPosition)
            
            
            // Check if coin is within catch distance
            if distance <= catchDistance {
                // Check if coin is within viewing angle
                let toCoin = simd_normalize(coinPosition - cameraPosition)
                let angle = acos(simd_dot(cameraForward, toCoin)) * 180.0 / Float.pi
                
                
                if angle <= catchAngle {
                    currentlyInRange.insert(coinName)
                    
                    // If this coin wasn't in range before, notify delegate
                    if !coinsInRange.contains(coinName) {
                        print("DEBUG: Coin \(coinName) entered range!")
                        delegate?.coinPlacementManager(self, didDetectCoinInRange: coinNode, distance: distance)
                    }
                }
            }
        }
        
        // Check for coins that are no longer in range
        for coinName in coinsInRange {
            if !currentlyInRange.contains(coinName) {
                if let coinNode = sceneView.scene.rootNode.childNode(withName: coinName, recursively: true) {
                    print("DEBUG: Coin \(coinName) left range!")
                    delegate?.coinPlacementManager(self, didLoseCoinInRange: coinNode)
                }
            }
        }
        
        coinsInRange = currentlyInRange
    }
    
    func catchCoin(withID coinID: UUID) {
        print("DEBUG: Attempting to catch coin with ID: \(coinID)")
        guard let sceneView = sceneView else {
            print("DEBUG: No scene view available")
            return
        }
        
        // Find the coin node by ID
        if let coinNode = sceneView.scene.rootNode.childNode(withName: coinID.uuidString, recursively: true) {
            print("DEBUG: Found coin node, starting catch animation")
            let coinPosition = simd_float3(coinNode.worldPosition.x, coinNode.worldPosition.y, coinNode.worldPosition.z)
            
            // Create enhanced animation by wrapping the existing coin
            print("DEBUG: Creating enhanced catch animation for existing coin")
            
            let enhancedCoin = CoinNode(modelNode: coinNode, sceneView: sceneView)
            enhancedCoin.position = coinNode.position
            enhancedCoin.name = coinNode.name
            
            if let parent = coinNode.parent {
                parent.addChildNode(enhancedCoin)
                coinNode.removeFromParentNode()
                
                enhancedCoin.catchCoin()
            } else {
                print("DEBUG: Using fallback catch animation")
                createCatchEffect(at: coinNode.worldPosition)
                coinNode.removeFromParentNode()
            }
            
            coinPositions.removeValue(forKey: coinID)
            coinsInRange.remove(coinID.uuidString)
            
            worldMapManager.removeGPSLocation(for: coinID)
            
            saveCoinPositions()
            
            delegate?.coinPlacementManager(self, didCatchCoin: coinID, at: coinPosition)
            
            print("Successfully caught coin \(coinID)")
        } else {
            print("DEBUG: Could not find coin node with ID: \(coinID)")
            print("DEBUG: Available coin positions: \(coinPositions.keys)")
            let allNodes = sceneView.scene.rootNode.childNodes
            print("DEBUG: All nodes in scene: \(allNodes.compactMap { $0.name })")
        }
    }
    
    private func createCatchEffect(at position: SCNVector3) {
        starEffectManager?.createCatchEffect(at: position)
    }
    
    private func distanceBetween(_ transform1: simd_float4x4, _ transform2: simd_float4x4) -> Float {
        let position1 = transform1.columns.3
        let position2 = transform2.columns.3
        
        let dx = position1.x - position2.x
        let dy = position1.y - position2.y
        let dz = position1.z - position2.z
        
        return sqrt(dx * dx + dy * dy + dz * dz)
    }
}

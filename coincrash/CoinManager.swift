//
//  CoinManager.swift
//  coincrash
//
//

import Foundation
import SceneKit
import ARKit
import GLTFSceneKit

class CoinManager {
    
    func createCoinNode() -> SCNNode {
        let modelNode = createBasicCoinModel()
        return modelNode
    }
    
    func createEnhancedCoinNode(sceneView: ARSCNView) -> CoinNode {
        let modelNode = createBasicCoinModel()
        return CoinNode(modelNode: modelNode, sceneView: sceneView)
    }
    
    private func createBasicCoinModel() -> SCNNode {
        if let coinLogoURL = Bundle.main.url(forResource: "CoinLogo", withExtension: "glb") {
            do {
                let sceneSource = GLTFSceneSource(url: coinLogoURL)
                let scene = try sceneSource.scene(options: [
                    .checkConsistency: true,
                    .convertUnitsToMeters: true,
                    .convertToYUp: true
                ])
                
                let coinNode = SCNNode()
                
                for childNode in scene.rootNode.childNodes {
                    preserveOriginalMaterials(node: childNode)
                    coinNode.addChildNode(childNode)
                }
                
                let scale: Float = 0.05
                coinNode.scale = SCNVector3(scale, scale, scale)
                
                addRotationAnimation(to: coinNode)
                
                return coinNode
                
            } catch {
            }
        } else {
            print("CoinLogo.glb not found in bundle")
        }
        
        return createFallbackCoin()
    }
    
    private func createFallbackCoin() -> SCNNode {
        let cylinderGeometry = SCNCylinder(radius: 0.025, height: 0.005)
        cylinderGeometry.firstMaterial?.diffuse.contents = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
        cylinderGeometry.firstMaterial?.specular.contents = UIColor.white
        cylinderGeometry.firstMaterial?.metalness.contents = 0.85
        cylinderGeometry.firstMaterial?.roughness.contents = 0.15
        
        let cylinderNode = SCNNode(geometry: cylinderGeometry)
        
        let logoNode = createCLogo()
        logoNode.position = SCNVector3(0, 0.0051, 0)
        cylinderNode.addChildNode(logoNode)
        
        addRotationAnimation(to: cylinderNode)
        
        print("Using fallback cylinder coin")
        return cylinderNode
    }
    
    private func createCLogo() -> SCNNode {
        let cText = SCNText(string: "C", extrusionDepth: 0.005)
        cText.font = UIFont.systemFont(ofSize: 0.15, weight: .bold)
        cText.firstMaterial?.diffuse.contents = UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
        cText.firstMaterial?.specular.contents = UIColor.white
        cText.firstMaterial?.metalness.contents = 0.85
        cText.firstMaterial?.roughness.contents = 0.15
        
        let textNode = SCNNode(geometry: cText)
        textNode.scale = SCNVector3(0.15, 0.15, 0.15)
        
        let (min, max) = textNode.boundingBox
        let dx = min.x + (max.x - min.x) / 2
        let dy = min.y + (max.y - min.y) / 2
        textNode.pivot = SCNMatrix4MakeTranslation(dx, dy, 0)
        
        textNode.eulerAngles.x = .pi / 2
        
        let containerNode = SCNNode()
        containerNode.addChildNode(textNode)
        
        return containerNode
    }
    
    private func addRotationAnimation(to node: SCNNode) {
        let rotateAction = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 10.0)
        let repeatForever = SCNAction.repeatForever(rotateAction)
        node.runAction(repeatForever)
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

//
//  ARSessionManager.swift
//  coincrash
//
//

import Foundation
import ARKit
import SceneKit

protocol ARSessionManagerDelegate: AnyObject {
    func arSessionDidRestoreCoins()
    func arSessionDidFailWithError(_ error: Error)
    func arSessionWasInterrupted()
    func arSessionInterruptionEnded()
}

class ARSessionManager: NSObject {
    
    weak var delegate: ARSessionManagerDelegate?
    weak var sceneView: ARSCNView?
    
    private var currentMode: ARObjectType = .indoor
    private var referenceImages: Set<ARReferenceImage> = []
    private var savedWorldMap: ARWorldMap?
    
    init(sceneView: ARSCNView, delegate: ARSessionManagerDelegate? = nil) {
        self.sceneView = sceneView
        self.delegate = delegate
        super.init()
        loadReferenceImages()
    }
    
    func setCurrentMode(_ mode: ARObjectType) {
        currentMode = mode
    }
    
    func getCurrentMode() -> ARObjectType {
        return currentMode
    }
    
    func setSavedWorldMap(_ worldMap: ARWorldMap?) {
        savedWorldMap = worldMap
    }
    
    func startARSession() {
        guard let sceneView = sceneView else { return }
        
        let configuration = ARWorldTrackingConfiguration()
        
        if currentMode == .indoor {
            configuration.planeDetection = [.horizontal, .vertical]
            configuration.detectionImages = referenceImages
            
            if #available(iOS 13.0, *) {
                configuration.frameSemantics = .personSegmentation
            }
            
            print("Started AR session in Indoor Mode")
        } else {
            configuration.planeDetection = [.horizontal]
            
            configuration.worldAlignment = .gravityAndHeading
            
            print("Started AR session in Outdoor Mode")
        }
        
        if let worldMap = savedWorldMap {
            configuration.initialWorldMap = worldMap
            print("Setting initialWorldMap for ARSession.")
        } else {
            print("No world map loaded, starting fresh session.")
        }
        
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func pauseSession() {
        sceneView?.session.pause()
    }
    
    func getCurrentWorldMap(completion: @escaping (ARWorldMap?, Error?) -> Void) {
        sceneView?.session.getCurrentWorldMap(completionHandler: completion)
    }
    
    private func loadReferenceImages() {
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            return
        }
        self.referenceImages = referenceImages
    }
}

extension ARSessionManager: ARSCNViewDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let imageAnchor = anchor as? ARImageAnchor {
            print("Image anchor detected: \(imageAnchor.referenceImage.name ?? "unknown")")
        }
        
        if anchor is ARPlaneAnchor {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.delegate?.arSessionDidRestoreCoins()
            }
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .normal:
            print("AR tracking is normal")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.delegate?.arSessionDidRestoreCoins()
            }
        case .limited(let reason):
            print("AR tracking limited: \(reason)")
        case .notAvailable:
            print("AR tracking not available")
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        delegate?.arSessionDidFailWithError(error)
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        delegate?.arSessionWasInterrupted()
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        delegate?.arSessionInterruptionEnded()
    }
}

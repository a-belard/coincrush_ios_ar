//
//  ViewController+ARDelegate.swift
//  coincrash
//
//

import Foundation
import ARKit
import SceneKit


extension ViewController {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Periodic save (every 30 seconds to avoid performance issues)
        if frame.timestamp.truncatingRemainder(dividingBy: 30) < 0.1 && !coinPlacementManager.coinPositions.isEmpty {
            saveCurrentState()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        arSessionManager.renderer(renderer, didAdd: node, for: anchor)
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        arSessionManager.session(session, cameraDidChangeTrackingState: camera)
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        arSessionManager.session(session, didFailWithError: error)
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        arSessionManager.sessionWasInterrupted(session)
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        arSessionManager.sessionInterruptionEnded(session)
    }
}


extension ViewController: ARSessionManagerDelegate {
    
    func arSessionDidRestoreCoins() {
        coinPlacementManager.restoreSavedCoins()
    }
    
    func arSessionDidFailWithError(_ error: Error) {
        showAlert(title: "AR Session Failed", message: error.localizedDescription)
    }
    
    func arSessionWasInterrupted() {
        showAlert(title: "Session Interrupted", message: "The AR session was interrupted.")
    }
    
    func arSessionInterruptionEnded() {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
}


extension ViewController: CoinPlacementManagerDelegate {
    
    func coinPlacementManager(_ manager: CoinPlacementManager, didPlaceCoin coinID: UUID, at position: simd_float3) {
        // Save coin with GPS coordinates if available
        if let location = locationManager.currentLocation {
            manager.saveCoinLocation(coinID: coinID, gpsLocation: location)
        }
        
        // Auto-save after placing (optional - could be done periodically instead)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.saveCurrentState()
        }
    }
    
    func coinPlacementManager(_ manager: CoinPlacementManager, didRemoveCoin coinID: UUID) {
        // Handle coin removal if needed
        print("Coin \(coinID) was removed from scene")
    }
    
    func coinPlacementManagerDidFailToFindSurface(_ manager: CoinPlacementManager) {
        showPlacementFeedback()
    }
    
    func coinPlacementManager(_ manager: CoinPlacementManager, didDetectCoinInRange coin: SCNNode, distance: Float) {
        print("DEBUG: didDetectCoinInRange called for coin: \(coin.name ?? "unknown")")
        DispatchQueue.main.async {
            
            // Store the coin ID for catching
            if let coinName = coin.name, let coinID = UUID(uuidString: coinName) {
                print("DEBUG: Setting current coin in range: \(coinID)")
                self.currentCoinInRange = coinID
                self.nearbyCoins.insert(coinName)
            }
        }
    }
    
    func coinPlacementManager(_ manager: CoinPlacementManager, didLoseCoinInRange coin: SCNNode) {
        print("DEBUG: didLoseCoinInRange called for coin: \(coin.name ?? "unknown")")
        DispatchQueue.main.async {
            if let coinName = coin.name {
                self.nearbyCoins.remove(coinName)
                
                // Update current coin in range
                if let coinID = UUID(uuidString: coinName), coinID == self.currentCoinInRange {
                    self.currentCoinInRange = nil
                }
            }
            
        }
    }
    
    func coinPlacementManager(_ manager: CoinPlacementManager, didCatchCoin coinID: UUID, at position: simd_float3) {
        print("DEBUG: didCatchCoin called for coin: \(coinID)")
        DispatchQueue.main.async {
            self.nearbyCoins.removeAll()
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
}


extension ViewController: LocationManagerDelegate {
    
    func locationManager(_ manager: LocationManager, didUpdateLocation location: CLLocation) {
    }
    
    func locationManagerDidFailWithError(_ error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorizationStatus(_ status: CLAuthorizationStatus) {
        switch status {
        case .denied, .restricted:
            print("Location permission denied")
            showLocationPermissionAlert()
        case .notDetermined:
            // Already handled in LocationManager
            break
        default:
            break
        }
    }
}

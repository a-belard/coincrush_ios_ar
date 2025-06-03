//
//  ViewController+Persistence.swift
//  coincrash
//
//

import Foundation
import ARKit


extension ViewController {
    
    func loadSavedData() {
        let (worldMap, positions) = worldMapManager.loadWorldMapAndPositions()
        
        if let map = worldMap {
            arSessionManager.setSavedWorldMap(map)
            print("Loaded saved world map")
        }
        
        if let positions = positions {
            coinPlacementManager.setCoinPositions(positions)
            print("Loaded \(positions.count) saved coin positions")
        }
    }
    
    func saveCurrentState() {
        arSessionManager.getCurrentWorldMap { [weak self] worldMap, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error getting world map: \(error)")
                return
            }
            
            guard let worldMap = worldMap else {
                print("No world map available")
                return
            }
            
            // Save both world map and coin positions
            self.worldMapManager.saveWorldMapAndPositions(worldMap, coinPositions: self.coinPlacementManager.coinPositions)
            print("Saved world map with \(self.coinPlacementManager.coinPositions.count) coin positions")
        }
    }
    
    private func saveWorldMap() {
        arSessionManager.getCurrentWorldMap { worldMap, error in
            guard let worldMap = worldMap else {
                self.showAlert(title: "Error", message: "Could not get current world map: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            self.worldMapManager.saveWorldMapAndPositions(worldMap, coinPositions: self.coinPlacementManager.coinPositions)
            self.showAlert(title: "Success", message: "World map and coin positions saved!")
        }
    }
}

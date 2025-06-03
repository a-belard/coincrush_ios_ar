import Foundation
import ARKit
import CoreLocation

class WorldMapManager {
    
    private let worldMapURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        .first!.appendingPathComponent("coinPosition.arworldmap")
    
    private let coinPositionsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        .first!.appendingPathComponent("coinPositions.plist")
    
    private let gpsLocationsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        .first!.appendingPathComponent("gpsLocations.plist")
    
    func saveWorldMapAndPositions(_ worldMap: ARWorldMap, coinPositions: [UUID: simd_float3]) {
        do {
            // Save world map
            let mapData = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
            try mapData.write(to: worldMapURL, options: [.atomic])
            
            // Convert UUID keys to strings for saving
            let stringKeyedPositions = Dictionary(uniqueKeysWithValues: coinPositions.map { (key, value) in
                (key.uuidString, [value.x, value.y, value.z])
            })
            
            // Save coin positions
            let positionsData = try PropertyListSerialization.data(fromPropertyList: stringKeyedPositions, format: .xml, options: 0)
            try positionsData.write(to: coinPositionsURL, options: [.atomic])
            print("Coin positions saved successfully")
            
        } catch {
            print("Error saving data: \(error.localizedDescription)")
        }
    }
    
    func loadWorldMapAndPositions() -> (ARWorldMap?, [UUID: simd_float3]?) {
        var worldMap: ARWorldMap?
        var coinPositions: [UUID: simd_float3]?
        
        // Load world map
        do {
            let mapData = try Data(contentsOf: worldMapURL)
            worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: mapData)
            print("World map loaded successfully")
        } catch {
            print("Error loading world map: \(error.localizedDescription)")
        }
        
        // Load coin positions
        do {
            let positionsData = try Data(contentsOf: coinPositionsURL)
            if let stringKeyedPositions = try PropertyListSerialization.propertyList(from: positionsData, options: [], format: nil) as? [String: [Float]] {
                
                // Convert back to UUID keys and simd_float3 values
                coinPositions = Dictionary(uniqueKeysWithValues: stringKeyedPositions.compactMap { (key, value) in
                    guard let uuid = UUID(uuidString: key), value.count == 3 else { return nil }
                    return (uuid, simd_float3(value[0], value[1], value[2]))
                })
                
                print("Coin positions loaded successfully: \(coinPositions?.count ?? 0) coins")
            }
        } catch {
            print("Error loading coin positions: \(error.localizedDescription)")
        }
        
        return (worldMap, coinPositions)
    }
    
    // Store GPS coordinates for each coin
    func saveCoinLocation(coinID: UUID, gpsLocation: CLLocation) {
        var gpsData = loadGPSLocations()
        
        let locationData: [String: Any] = [
            "latitude": gpsLocation.coordinate.latitude,
            "longitude": gpsLocation.coordinate.longitude,
            "altitude": gpsLocation.altitude,
            "horizontalAccuracy": gpsLocation.horizontalAccuracy,
            "verticalAccuracy": gpsLocation.verticalAccuracy,
            "timestamp": gpsLocation.timestamp.timeIntervalSince1970
        ]
        
        gpsData[coinID.uuidString] = locationData
        
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: gpsData, format: .xml, options: 0)
            try data.write(to: gpsLocationsURL, options: [.atomic])
            print("GPS location saved for coin \(coinID)")
        } catch {
            print("Error saving GPS location: \(error.localizedDescription)")
        }
    }
    
    // Load GPS coordinates for all coins
    func loadGPSLocations() -> [String: [String: Any]] {
        do {
            let data = try Data(contentsOf: gpsLocationsURL)
            if let gpsData = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: [String: Any]] {
                return gpsData
            }
        } catch {
            print("Error loading GPS locations: \(error.localizedDescription)")
        }
        return [:]
    }
    
    // Get GPS location for specific coin
    func getGPSLocation(for coinID: UUID) -> CLLocation? {
        let gpsData = loadGPSLocations()
        
        guard let locationData = gpsData[coinID.uuidString],
              let latitude = locationData["latitude"] as? Double,
              let longitude = locationData["longitude"] as? Double,
              let altitude = locationData["altitude"] as? Double,
              let horizontalAccuracy = locationData["horizontalAccuracy"] as? Double,
              let verticalAccuracy = locationData["verticalAccuracy"] as? Double,
              let timestamp = locationData["timestamp"] as? TimeInterval else {
            return nil
        }
        
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let date = Date(timeIntervalSince1970: timestamp)
        
        return CLLocation(
            coordinate: coordinate,
            altitude: altitude,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            timestamp: date
        )
    }
    
    // Get all coins with their GPS locations (for map display)
    func getAllCoinsWithGPS() -> [(UUID, simd_float3, CLLocation)] {
        let (_, coinPositions) = loadWorldMapAndPositions()
        let gpsData = loadGPSLocations()
        
        var coinsWithGPS: [(UUID, simd_float3, CLLocation)] = []
        
        if let positions = coinPositions {
            for (coinID, arPosition) in positions {
                if let gpsLocation = getGPSLocation(for: coinID) {
                    coinsWithGPS.append((coinID, arPosition, gpsLocation))
                }
            }
        }
        
        return coinsWithGPS
    }
    
    // Remove GPS data when coin is deleted
    func removeGPSLocation(for coinID: UUID) {
        var gpsData = loadGPSLocations()
        gpsData.removeValue(forKey: coinID.uuidString)
        
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: gpsData, format: .xml, options: 0)
            try data.write(to: gpsLocationsURL, options: [.atomic])
            print("GPS location removed for coin \(coinID)")
        } catch {
            print("Error removing GPS location: \(error.localizedDescription)")
        }
    }
}

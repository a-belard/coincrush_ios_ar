import Foundation
import ARKit
import CoreLocation

class ARWorldManager {
    static let shared = ARWorldManager()
    private let locationManager = CLLocationManager()
    private var placedObjects: [ARObject] = []
    private var worldMap: ARWorldMap?
    
    private init() {
        setupLocationManager()
        loadPlacedObjects()
    }
    
    private func setupLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Object Management
    
    func placeObject(type: ARObjectType, transform: simd_float4x4, modelName: String, imageAnchor: String? = nil) {
        let location = type == .outdoor ? locationManager.location : nil
        let object = ARObject(type: type, transform: transform, modelName: modelName, location: location, imageAnchor: imageAnchor)
        placedObjects.append(object)
        savePlacedObjects()
    }
    
    func getPlacedObjects() -> [ARObject] {
        return placedObjects
    }
    
    func removeObject(withId id: UUID) {
        placedObjects.removeAll { $0.id == id }
        savePlacedObjects()
    }
    
    // MARK: - World Map Management
    
    func saveWorldMap(_ worldMap: ARWorldMap) {
        self.worldMap = worldMap
        saveWorldMapToDisk()
    }
    
    func loadWorldMap() -> ARWorldMap? {
        if worldMap == nil {
            loadWorldMapFromDisk()
        }
        return worldMap
    }
    
    // MARK: - Private Methods
    
    private func savePlacedObjects() {
        if let data = try? JSONEncoder().encode(placedObjects) {
            UserDefaults.standard.set(data, forKey: "placedObjects")
        }
    }
    
    private func loadPlacedObjects() {
        if let data = UserDefaults.standard.data(forKey: "placedObjects"),
           let objects = try? JSONDecoder().decode([ARObject].self, from: data) {
            placedObjects = objects
        }
    }
    
    private func saveWorldMapToDisk() {
        guard let worldMap = worldMap else { return }
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
            try data.write(to: getWorldMapURL())
        } catch {
            print("Error saving world map: \(error)")
        }
    }
    
    private func loadWorldMapFromDisk() {
        do {
            let data = try Data(contentsOf: getWorldMapURL())
            worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
        } catch {
            print("Error loading world map: \(error)")
        }
    }
    
    private func getWorldMapURL() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("worldMap")
    }
} 
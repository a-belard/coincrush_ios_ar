import Foundation
import ARKit
import CoreLocation

enum ARObjectType: String, Codable {
    case indoor
    case outdoor
}

class ARObject: Codable {
    let id: UUID
    let type: ARObjectType
    let transform: simd_float4x4
    let modelName: String
    var location: CLLocation?
    var imageAnchor: String?
    
    init(id: UUID = UUID(), type: ARObjectType, transform: simd_float4x4, modelName: String, location: CLLocation? = nil, imageAnchor: String? = nil) {
        self.id = id
        self.type = type
        self.transform = transform
        self.modelName = modelName
        self.location = location
        self.imageAnchor = imageAnchor
    }
    
    enum CodingKeys: String, CodingKey {
        case id, type, transform, modelName, location, imageAnchor
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(ARObjectType.self, forKey: .type)
        let transformArray = try container.decode([Float].self, forKey: .transform)
        transform = simd_float4x4(
            SIMD4<Float>(transformArray[0], transformArray[1], transformArray[2], transformArray[3]),
            SIMD4<Float>(transformArray[4], transformArray[5], transformArray[6], transformArray[7]),
            SIMD4<Float>(transformArray[8], transformArray[9], transformArray[10], transformArray[11]),
            SIMD4<Float>(transformArray[12], transformArray[13], transformArray[14], transformArray[15])
        )
        modelName = try container.decode(String.self, forKey: .modelName)
        if let locationData = try container.decodeIfPresent([Double].self, forKey: .location) {
            location = CLLocation(latitude: locationData[0], longitude: locationData[1])
        } else {
            location = nil
        }
        imageAnchor = try container.decodeIfPresent(String.self, forKey: .imageAnchor)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        let transformArray = [
            transform.columns.0.x, transform.columns.0.y, transform.columns.0.z, transform.columns.0.w,
            transform.columns.1.x, transform.columns.1.y, transform.columns.1.z, transform.columns.1.w,
            transform.columns.2.x, transform.columns.2.y, transform.columns.2.z, transform.columns.2.w,
            transform.columns.3.x, transform.columns.3.y, transform.columns.3.z, transform.columns.3.w
        ]
        try container.encode(transformArray, forKey: .transform)
        try container.encode(modelName, forKey: .modelName)
        if let location = location {
            try container.encode([location.coordinate.latitude, location.coordinate.longitude], forKey: .location)
        }
        try container.encodeIfPresent(imageAnchor, forKey: .imageAnchor)
    }
} 
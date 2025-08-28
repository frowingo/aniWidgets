import Foundation
 // frowi - Alternative Models
public struct WidgetDesign: Codable, Identifiable, Hashable {
   public let id: String
   public let name: String
   public let description: String
   public let category: String
   public let frameCount: Int
   public let animationDuration: Double
   public let frameInterval: Double
   public let thumbnailURL: String
   public let framesBaseURL: String
   public let isDownloaded: Bool
    
    // Computed property for preview image URL
   public var previewImageURL: URL? {
        // test01 için bundle'dan gerçek frame'i kullan
        if id == "test01" {
            if let bundlePath = Bundle.main.path(forResource: "frame_01", ofType: "png") {
                return URL(fileURLWithPath: bundlePath)
            }
        }
        return URL(string: thumbnailURL)
    }
    
   public init(id: String, name: String, description: String, category: String = "general", frameCount: Int = 24, animationDuration: Double = 12.0, frameInterval: Double = 0.5, thumbnailURL: String, framesBaseURL: String, isDownloaded: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.frameCount = frameCount
        self.animationDuration = animationDuration
        self.frameInterval = frameInterval
        self.thumbnailURL = thumbnailURL
        self.framesBaseURL = framesBaseURL
        self.isDownloaded = isDownloaded
    }
}

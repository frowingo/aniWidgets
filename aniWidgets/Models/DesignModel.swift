import Foundation

// MARK: - Design Models
typealias DesignModel = WidgetDesign
struct WidgetDesign: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let category: String
    let frameCount: Int
    let animationDuration: Double
    let frameInterval: Double
    let thumbnailURL: String
    let framesBaseURL: String
    let isDownloaded: Bool
    
    // Computed property for preview image URL
    var previewImageURL: URL? {
        // test01 için bundle'dan gerçek frame'i kullan
        if id == "test01" {
            if let bundlePath = Bundle.main.path(forResource: "frame_01", ofType: "png") {
                return URL(fileURLWithPath: bundlePath)
            }
        }
        return URL(string: thumbnailURL)
    }
    
    init(id: String, name: String, description: String, category: String = "general", frameCount: Int = 24, animationDuration: Double = 12.0, frameInterval: Double = 0.5, thumbnailURL: String, framesBaseURL: String, isDownloaded: Bool = false) {
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

// Featured designs configuration (stored in App Group)
struct FeaturedConfig: Codable {
    var designs: [String]
    var maxCount: Int
    
    init(designs: [String] = []) {
        self.maxCount = 4
        self.designs = Array(designs.prefix(maxCount))
    }
    
    mutating func addDesign(_ designId: String) -> Bool {
        // Check if already exists
        if designs.contains(designId) {
            return false
        }
        
        // Check if we have space
        if designs.count >= maxCount {
            return false
        }
        
        designs.append(designId)
        return true
    }
    
    mutating func removeDesign(_ designId: String) {
        designs.removeAll { $0 == designId }
    }
    
    mutating func reorderDesigns(_ newOrder: [String]) {
        // Filter to only include valid designs and respect maxCount
        let validDesigns = newOrder.filter { designs.contains($0) }
        designs = Array(validDesigns.prefix(maxCount))
    }
}

// MARK: - Widget Instance State
struct WidgetInstanceState: Codable {
    let instanceId: String
    var currentFrame: Int
    var isAnimating: Bool
    var animationStartTime: Date?
    var designId: String
    var lastInteraction: Date
    
    init(instanceId: String, designId: String, currentFrame: Int = 1) {
        self.instanceId = instanceId
        self.designId = designId
        self.currentFrame = currentFrame
        self.isAnimating = false
        self.animationStartTime = nil
        self.lastInteraction = Date()
    }
}

// MARK: - Design Manifest
struct DesignManifest: Codable {
    let designId: String
    let name: String
    let frameCount: Int
    let frameInterval: Double
    let downloadedAt: Date
    let frameUrls: [String]
    
    var framesDirectory: URL {
        AppGroupManager.shared.designFramesDirectory(for: designId)
    }
}

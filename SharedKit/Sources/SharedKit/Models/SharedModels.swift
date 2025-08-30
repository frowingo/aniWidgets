import Foundation

// MARK: - Widget Data Models

/// Widget için ana veri modeli
public struct WidgetEntry: Codable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let animationFrames: [String] // frame dosya adları
    public let frameCount: Int
    public let category: String
    public let isFavorite: Bool
    public let lastUpdated: Date
    
    public init(
        id: String,
        title: String,
        subtitle: String? = nil,
        animationFrames: [String] = [],
        frameCount: Int = 0,
        category: String = "default",
        isFavorite: Bool = false,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.animationFrames = animationFrames
        self.frameCount = frameCount
        self.category = category
        self.isFavorite = isFavorite
        self.lastUpdated = lastUpdated
    }
}

/// Widget için zamanlama entry modeli
public struct WidgetTimelineEntry: Codable {
    public let date: Date
    public let widgetEntry: WidgetEntry
    public let displayRelevance: Double
    
    public init(date: Date, widgetEntry: WidgetEntry, displayRelevance: Double = 1.0) {
        self.date = date
        self.widgetEntry = widgetEntry
        self.displayRelevance = displayRelevance
    }
}

/// App ayarları
public struct AppSettings: Codable {
    public let refreshInterval: TimeInterval
    public let enableNotifications: Bool
    public let preferredCategories: [String]
    public let lastSyncDate: Date?
    
    public init(
        refreshInterval: TimeInterval = 1800, // 30 minutes
        enableNotifications: Bool = true,
        preferredCategories: [String] = [],
        lastSyncDate: Date? = nil
    ) {
        self.refreshInterval = refreshInterval
        self.enableNotifications = enableNotifications
        self.preferredCategories = preferredCategories
        self.lastSyncDate = lastSyncDate
    }
}

// MARK: - Animation Design

public struct AnimationDesign: Codable, Hashable {
    public let id: String
    public let name: String
    public let podiumName: String
    public let frameCount: Int
    public let frameRate: Double
    public let createdAt: Date
    
    public init(id: String, name: String, podiumName: String , frameCount: Int, frameRate: Double = 10.0) {
        self.id = id
        self.name = name
        self.podiumName = podiumName
        self.frameCount = frameCount
        self.frameRate = frameRate
        self.createdAt = Date()
    }
}

// MARK: - Widget Design
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


// MARK: - Featured Configuration

public struct FeaturedConfig: Codable {
    public var designs: [String]
    public var maxCount: Int
    
    public init(designs: [String] = []) {
        self.maxCount = 4
        self.designs = Array(designs.prefix(maxCount))
    }
}

// MARK: - Error Types

public enum SharedKitError: Error, LocalizedError {
    case appGroupNotFound
    case fileNotFound(String)
    case invalidData(String)
    case writeError(String)
    case readError(String)
    
    public var errorDescription: String? {
        switch self {
        case .appGroupNotFound:
            return "App Group container not found"
        case .fileNotFound(let file):
            return "File not found: \(file)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .writeError(let message):
            return "Write error: \(message)"
        case .readError(let message):
            return "Read error: \(message)"
        }
    }
}

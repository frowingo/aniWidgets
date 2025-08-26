import AppIntents
import WidgetKit
import SharedKit

// MARK: - Widget App Intents (iOS 17+)

@available(iOS 17.0, *)
struct ToggleFavoriteIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Favorite"
    static var description = IntentDescription("Toggle favorite status of the current widget design")
    
    @Parameter(title: "Design ID")
    var designId: String
    
    func perform() async throws -> some IntentResult {
        let logger = SharedLogger.shared
        logger.info("ToggleFavoriteIntent called for design: \(designId)")
        
        // Here you would implement the favorite toggle logic
        // For now, just reload the widget
        WidgetCenter.shared.reloadTimelines(ofKind: SharedConstants.widgetKind)
        
        return .result()
    }
}

@available(iOS 17.0, *)
struct RefreshWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Widget"
    static var description = IntentDescription("Refresh the widget timeline")
    
    func perform() async throws -> some IntentResult {
        let logger = SharedLogger.shared
        logger.info("RefreshWidgetIntent called")
        
        WidgetCenter.shared.reloadTimelines(ofKind: SharedConstants.widgetKind)
        
        return .result()
    }
}

// MARK: - Widget URL Scheme

struct WidgetDeepLink {
    static func handleURL(_ url: URL) {
        let logger = SharedLogger.shared
        logger.info("Widget deep link received: \(url.absoluteString)")
        
        // Parse URL and handle navigation
        // Example: aniwidgets://design/manuelTest02
        if url.scheme == "aniwidgets" {
            switch url.host {
            case "design":
                let designId = url.lastPathComponent
                logger.info("Opening design: \(designId)")
                // Navigate to design detail
            case "settings":
                logger.info("Opening settings")
                // Navigate to settings
            default:
                logger.info("Unknown deep link host: \(url.host ?? "nil")")
            }
        }
    }
}

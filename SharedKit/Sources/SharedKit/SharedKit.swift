// SharedKit - Shared functionality between App and Widget

@_exported import Foundation
@_exported import UIKit

// Public API
public typealias AppStore = AppGroupStore

// Constants
public struct SharedConstants {
    public static let appGroupIdentifier = "group.Iworf.aniWidgets"
    public static let widgetKind = "MiniWidget"
    
    // File names
    public static let currentWidgetDataFile = "current_widget_data.json"
    public static let availableDesignsFile = "available_designs.json"
    public static let appSettingsFile = "app_settings.json"
    public static let favoritesFile = "favorites.json"
    
    // Refresh intervals
    public static let minRefreshInterval: TimeInterval = 900  // 15 minutes
    public static let defaultRefreshInterval: TimeInterval = 1800 // 30 minutes
    public static let maxRefreshInterval: TimeInterval = 3600 // 1 hour
}

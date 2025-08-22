import Foundation
import SwiftUI
import WidgetKit
import os.log

@MainActor
class DesignManager: ObservableObject {
    static let shared = DesignManager()
    
    private let logger = Logger(subsystem: "com.aniwidgets.logging", category: "DesignManager")
    private let appGroupManager = AppGroupManager.shared
    private let downloader = DesignDownloader()
    
    @Published var availableDesigns: [WidgetDesign] = []
    @Published var featuredConfig = FeaturedConfig()
    @Published var isLoading = false
    @Published var downloadProgress: [String: Double] = [:]
    @Published var hasPendingChanges = false
    @Published var isSyncing = false
    
    private init() {
        logger.info("🎨 DesignManager initialized")
        loadFeaturedConfig()
        loadAvailableDesigns()
    }
    
    // MARK: - Available Designs (Mock API data for now)
    func loadAvailableDesigns() {
        availableDesigns = [
            // Test Category - Only test01 has real assets
            WidgetDesign(
                id: "test01",
                name: "test01",
                description: "frowing'in özel animasyonlu tasarımı",
                category: "test",
                thumbnailURL: "https://example.com/thumbnails/test01.png",
                framesBaseURL: "https://example.com/frames/test01"
            ),
            WidgetDesign(
                id: "test02",
                name: "test02",
                description: "Coming soon - Enhanced pulse variant",
                category: "test",
                thumbnailURL: "https://example.com/thumbnails/test02.png",
                framesBaseURL: "https://example.com/frames/test02"
            ),
            WidgetDesign(
                id: "test03",
                name: "test03",
                description: "Coming soon - Smooth wave animation",
                category: "test",
                thumbnailURL: "https://example.com/thumbnails/test03.png",
                framesBaseURL: "https://example.com/frames/test03"
            ),
            WidgetDesign(
                id: "test04",
                name: "test04",
                description: "Coming soon - Dynamic gradient effect",
                category: "test",
                thumbnailURL: "https://example.com/thumbnails/test04.png",
                framesBaseURL: "https://example.com/frames/test04"
            ),
            
            // Nature Category
            WidgetDesign(
                id: "nature01",
                name: "nature01",
                description: "Coming soon - Forest breeze animation",
                category: "nature",
                thumbnailURL: "https://example.com/thumbnails/nature01.png",
                framesBaseURL: "https://example.com/frames/nature01"
            ),
            WidgetDesign(
                id: "nature02",
                name: "nature02",
                description: "Coming soon - Ocean wave motion",
                category: "nature",
                thumbnailURL: "https://example.com/thumbnails/nature02.png",
                framesBaseURL: "https://example.com/frames/nature02"
            ),
            WidgetDesign(
                id: "nature03",
                name: "nature03",
                description: "Coming soon - Mountain sunrise glow",
                category: "nature",
                thumbnailURL: "https://example.com/thumbnails/nature03.png",
                framesBaseURL: "https://example.com/frames/nature03"
            ),
            
            // Abstract Category
            WidgetDesign(
                id: "abstract01",
                name: "abstract01",
                description: "Coming soon - Geometric patterns",
                category: "abstract",
                thumbnailURL: "https://example.com/thumbnails/abstract01.png",
                framesBaseURL: "https://example.com/frames/abstract01"
            ),
            WidgetDesign(
                id: "abstract02",
                name: "abstract02",
                description: "Coming soon - Fluid shapes motion",
                category: "abstract",
                thumbnailURL: "https://example.com/thumbnails/abstract02.png",
                framesBaseURL: "https://example.com/frames/abstract02"
            ),
            WidgetDesign(
                id: "abstract03",
                name: "abstract03",
                description: "Coming soon - Particle system animation",
                category: "abstract",
                thumbnailURL: "https://example.com/thumbnails/abstract03.png",
                framesBaseURL: "https://example.com/frames/abstract03"
            )
        ]
        Task {
            logger.info("🎨 Loaded \(self.availableDesigns.count) available designs")
        }
    }
    
    // MARK: - Featured Configuration
    func loadFeaturedConfig() {
        do {
            featuredConfig = try appGroupManager.loadData(FeaturedConfig.self, from: appGroupManager.featuredConfigPath)
            logger.info("📋 Featured config loaded: \(self.featuredConfig.designs)")
        } catch {
            logger.info("📋 No featured config found, creating default")
            featuredConfig = FeaturedConfig()
        }
    }
    
    func saveFeaturedConfig() {
        do {
            try appGroupManager.saveData(featuredConfig, to: appGroupManager.featuredConfigPath)
            logger.info("💾 Featured config saved")
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            logger.error("❌ Failed to save featured config: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Featured Management
    func addToFeatured(_ design: WidgetDesign) async {
        guard featuredConfig.addDesign(design.id) else {
            logger.warning("⚠️ Could not add design to featured (already exists or full)")
            return
        }
        
        hasPendingChanges = true
        saveFeaturedConfig()
    }
    
    func removeFromFeatured(_ designId: String) {
        featuredConfig.removeDesign(designId)
        hasPendingChanges = true
        saveFeaturedConfig()
    }
    
    func removeFromFeatured(at index: Int) {
        guard index < featuredConfig.designs.count else { return }
        let designId = featuredConfig.designs[index]
        removeFromFeatured(designId)
    }
    
    func reorderFeatured(_ newOrder: [String]) {
        featuredConfig.reorderDesigns(newOrder)
        hasPendingChanges = true
        saveFeaturedConfig()
    }
    
    // MARK: - Sync Operations
    func syncFeaturedDesigns() async {
        guard hasPendingChanges else { return }
        
        isSyncing = true
        logger.info("🔄 Starting sync for featured designs")
        
        // Get current featured design IDs
        let currentFeaturedIds = Set(featuredConfig.designs)
        
        // Download new designs
        for designId in currentFeaturedIds {
            if let design = availableDesigns.first(where: { $0.id == designId }) {
                await downloadDesign(design)
            }
        }
        
        // Cleanup unused designs
        await cleanupUnusedDesigns()
        
        hasPendingChanges = false
        isSyncing = false
        logger.info("✅ Sync completed for featured designs")
    }
    
    // MARK: - Download Management
    func downloadDesign(_ design: WidgetDesign) async {
        logger.info("⬇️ Starting download for design: \(design.name)")
        isLoading = true
        downloadProgress[design.id] = 0.0
        
        do {
            try await downloader.downloadDesign(design) { progress in
                Task { @MainActor in
                    self.downloadProgress[design.id] = progress
                }
            }
            
            downloadProgress.removeValue(forKey: design.id)
            logger.info("✅ Download completed for design: \(design.name)")
            
        } catch {
            downloadProgress.removeValue(forKey: design.id)
            logger.error("❌ Download failed for design: \(design.name) - \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    private func cleanupUnusedDesigns() async {
        let featuredIds = Set(featuredConfig.designs)
        do {
            try appGroupManager.cleanupUnusedDesigns(keepingIds: featuredIds)
        } catch {
            logger.error("❌ Cleanup failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    func isDesignFeatured(_ designId: String) -> Bool {
        return featuredConfig.designs.contains(designId)
    }
    
    func isDesignDownloaded(_ designId: String) -> Bool {
        return appGroupManager.designExists(designId)
    }
    
    var featuredDesigns: [WidgetDesign] {
        return featuredConfig.designs.compactMap { designId in
            availableDesigns.first { $0.id == designId }
        }
    }
    
    func getFeaturedDesign(for slotIndex: Int) -> WidgetDesign? {
        guard slotIndex < featuredConfig.designs.count else { return nil }
        let designId = featuredConfig.designs[slotIndex]
        return availableDesigns.first { $0.id == designId }
    }
}

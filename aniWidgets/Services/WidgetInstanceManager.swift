import Foundation
import WidgetKit
import os.log

class WidgetInstanceManager {
    static let shared = WidgetInstanceManager()
    
    private let logger = Logger(subsystem: "com.aniwidgets.logging", category: "WidgetInstance")
    private let appGroupManager = AppGroupManager.shared
    
    private init() {
        logger.info("🔧 WidgetInstanceManager initialized")
    }
    
    // MARK: - Instance Management
    func createInstance(designId: String) -> String {
        let instanceId = UUID().uuidString
        let state = WidgetInstanceState(instanceId: instanceId, designId: designId)
        
        do {
            try saveInstanceState(state)
            logger.info("🆕 Created new widget instance: \(instanceId) for design: \(designId)")
            return instanceId
        } catch {
            logger.error("❌ Failed to create instance: \(error.localizedDescription)")
            return instanceId // Return ID even if save failed
        }
    }
    
    func loadInstanceState(_ instanceId: String) -> WidgetInstanceState? {
        let statePath = appGroupManager.instanceStatePath(for: instanceId)
        
        do {
            let state = try appGroupManager.loadData(WidgetInstanceState.self, from: statePath)
            logger.info("📖 Loaded instance state: \(instanceId)")
            return state
        } catch {
            logger.warning("⚠️ Could not load instance state for \(instanceId): \(error.localizedDescription)")
            return nil
        }
    }
    
    func saveInstanceState(_ state: WidgetInstanceState) throws {
        let statePath = appGroupManager.instanceStatePath(for: state.instanceId)
        try appGroupManager.saveData(state, to: statePath)
        logger.info("💾 Saved instance state: \(state.instanceId)")
    }
    
    func deleteInstance(_ instanceId: String) {
        let statePath = appGroupManager.instanceStatePath(for: instanceId)
        
        do {
            if FileManager.default.fileExists(atPath: statePath.path) {
                try FileManager.default.removeItem(at: statePath)
                logger.info("🗑️ Deleted instance: \(instanceId)")
            }
        } catch {
            logger.error("❌ Failed to delete instance \(instanceId): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Animation Control
    func startAnimation(for instanceId: String) -> Bool {
        guard var state = loadInstanceState(instanceId) else {
            logger.error("❌ Cannot start animation - instance not found: \(instanceId)")
            return false
        }
        
        guard !state.isAnimating else {
            logger.info("ℹ️ Animation already running for instance: \(instanceId)")
            return true
        }
        
        state.isAnimating = true
        state.animationStartTime = Date()
        state.currentFrame = 1
        state.lastInteraction = Date()
        
        do {
            try saveInstanceState(state)
            logger.info("🎬 Started animation for instance: \(instanceId)")
            return true
        } catch {
            logger.error("❌ Failed to save animation state for \(instanceId): \(error.localizedDescription)")
            return false
        }
    }
    
    func stopAnimation(for instanceId: String) -> Bool {
        guard var state = loadInstanceState(instanceId) else {
            logger.error("❌ Cannot stop animation - instance not found: \(instanceId)")
            return false
        }
        
        state.isAnimating = false
        state.animationStartTime = nil
        state.currentFrame = 1
        
        do {
            try saveInstanceState(state)
            logger.info("⏹️ Stopped animation for instance: \(instanceId)")
            return true
        } catch {
            logger.error("❌ Failed to save stop animation state for \(instanceId): \(error.localizedDescription)")
            return false
        }
    }
    
    func updateFrame(for instanceId: String, frame: Int) -> Bool {
        guard var state = loadInstanceState(instanceId) else {
            logger.error("❌ Cannot update frame - instance not found: \(instanceId)")
            return false
        }
        
        state.currentFrame = frame
        
        do {
            try saveInstanceState(state)
            return true
        } catch {
            logger.error("❌ Failed to update frame for \(instanceId): \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Design Management
    func updateInstanceDesign(_ instanceId: String, newDesignId: String) -> Bool {
        guard var state = loadInstanceState(instanceId) else {
            logger.error("❌ Cannot update design - instance not found: \(instanceId)")
            return false
        }
        
        // Stop any ongoing animation
        state.isAnimating = false
        state.animationStartTime = nil
        state.currentFrame = 1
        state.designId = newDesignId
        
        do {
            try saveInstanceState(state)
            logger.info("🎨 Updated design for instance \(instanceId) to \(newDesignId)")
            return true
        } catch {
            logger.error("❌ Failed to update design for \(instanceId): \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Cleanup
    func cleanupOldInstances(olderThan timeInterval: TimeInterval = 30 * 24 * 60 * 60) { // 30 days
        let cutoffDate = Date().addingTimeInterval(-timeInterval)
        
        do {
            let instanceFiles = try FileManager.default.contentsOfDirectory(
                at: appGroupManager.instancesDirectory,
                includingPropertiesForKeys: [.contentModificationDateKey]
            )
            
            for fileURL in instanceFiles {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.contentModificationDateKey])
                    if let modificationDate = resourceValues.contentModificationDate,
                       modificationDate < cutoffDate {
                        try FileManager.default.removeItem(at: fileURL)
                        logger.info("🧹 Cleaned up old instance: \(fileURL.lastPathComponent)")
                    }
                } catch {
                    logger.error("❌ Failed to check/delete instance file \(fileURL.path): \(error)")
                }
            }
        } catch {
            logger.error("❌ Failed to enumerate instance files: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Statistics
    func getAllInstances() -> [WidgetInstanceState] {
        do {
            let instanceFiles = try FileManager.default.contentsOfDirectory(
                at: appGroupManager.instancesDirectory,
                includingPropertiesForKeys: nil
            )
            
            return instanceFiles.compactMap { fileURL in
                let instanceId = fileURL.deletingPathExtension().lastPathComponent
                return loadInstanceState(instanceId)
            }
        } catch {
            logger.error("❌ Failed to load all instances: \(error.localizedDescription)")
            return []
        }
    }
    
    func getActiveInstancesCount() -> Int {
        let instances = getAllInstances()
        let recentThreshold = Date().addingTimeInterval(-24 * 60 * 60) // 24 hours
        return instances.filter { $0.lastInteraction > recentThreshold }.count
    }
}

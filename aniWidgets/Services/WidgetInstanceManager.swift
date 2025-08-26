import Foundation
import SwiftUI
import SharedKit
import os.log

// MARK: - Widget Instance State

struct WidgetInstanceState: Codable {
    let instanceId: String
    let designId: String
    let currentFrameIndex: Int
    let isAnimating: Bool
    let lastUpdateDate: Date
    let animationSpeed: Double
    
    init(instanceId: String, designId: String, currentFrameIndex: Int = 0, isAnimating: Bool = true, animationSpeed: Double = 0.1) {
        self.instanceId = instanceId
        self.designId = designId
        self.currentFrameIndex = currentFrameIndex
        self.isAnimating = isAnimating
        self.lastUpdateDate = Date()
        self.animationSpeed = animationSpeed
    }
}

// MARK: - Widget Instance Manager

class WidgetInstanceManager: ObservableObject {
    static let shared = WidgetInstanceManager()
    
    private let logger = SharedLogger.shared
    private let appGroupManager = AppGroupManager.shared
    
    @Published private var activeInstances: [String: WidgetInstanceState] = [:]
    
    private init() {
        logger.info("🔧 WidgetInstanceManager initialized")
        loadActiveInstances()
    }
    
    // MARK: - Instance Management
    
    func loadInstanceState(_ instanceId: String) -> WidgetInstanceState? {
        do {
            let path = appGroupManager.instanceStatePath(for: instanceId)
            return try appGroupManager.loadData(WidgetInstanceState.self, from: path)
        } catch {
            logger.error("Failed to load instance state for \(instanceId): \(error.localizedDescription)")
            return nil
        }
    }
    
    func saveInstanceState(_ state: WidgetInstanceState) throws {
        let path = appGroupManager.instanceStatePath(for: state.instanceId)
        try appGroupManager.saveData(state, to: path)
        
        DispatchQueue.main.async {
            self.activeInstances[state.instanceId] = state
        }
        
        logger.info("Saved instance state for \(state.instanceId)")
    }
    
    func createNewInstance(designId: String) -> WidgetInstanceState {
        let instanceId = UUID().uuidString
        let newState = WidgetInstanceState(instanceId: instanceId, designId: designId)
        
        do {
            try saveInstanceState(newState)
            logger.info("Created new instance \(instanceId) for design \(designId)")
        } catch {
            logger.error("Failed to save new instance state: \(error.localizedDescription)")
        }
        
        return newState
    }
    
    func updateInstanceFrame(_ instanceId: String, frameIndex: Int) {
        guard var state = activeInstances[instanceId] else {
            logger.warning("Attempted to update non-existent instance \(instanceId)")
            return
        }
        
        let updatedState = WidgetInstanceState(
            instanceId: state.instanceId,
            designId: state.designId,
            currentFrameIndex: frameIndex,
            isAnimating: state.isAnimating,
            animationSpeed: state.animationSpeed
        )
        
        do {
            try saveInstanceState(updatedState)
        } catch {
            logger.error("Failed to update instance frame: \(error.localizedDescription)")
        }
    }
    
    func toggleInstanceAnimation(_ instanceId: String) {
        guard var state = activeInstances[instanceId] else {
            logger.warning("Attempted to toggle animation for non-existent instance \(instanceId)")
            return
        }
        
        let updatedState = WidgetInstanceState(
            instanceId: state.instanceId,
            designId: state.designId,
            currentFrameIndex: state.currentFrameIndex,
            isAnimating: !state.isAnimating,
            animationSpeed: state.animationSpeed
        )
        
        do {
            try saveInstanceState(updatedState)
        } catch {
            logger.error("Failed to toggle instance animation: \(error.localizedDescription)")
        }
    }
    
    func deleteInstance(_ instanceId: String) {
        let path = appGroupManager.instanceStatePath(for: instanceId)
        
        do {
            try FileManager.default.removeItem(at: path)
            DispatchQueue.main.async {
                self.activeInstances.removeValue(forKey: instanceId)
            }
            logger.info("Deleted instance \(instanceId)")
        } catch {
            logger.error("Failed to delete instance \(instanceId): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Cleanup and Maintenance
    
    func cleanupOldInstances() {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        for (instanceId, state) in activeInstances {
            if state.lastUpdateDate < cutoffDate {
                deleteInstance(instanceId)
                logger.info("Cleaned up old instance \(instanceId)")
            }
        }
    }
    
    func getAllInstances() -> [WidgetInstanceState] {
        return Array(activeInstances.values)
    }
    
    func getInstancesForDesign(_ designId: String) -> [WidgetInstanceState] {
        return activeInstances.values.filter { $0.designId == designId }
    }
    
    // MARK: - Private Methods
    
    private func loadActiveInstances() {
        // Load all existing instances from App Group directory
        let instancesDirectory = appGroupManager.appGroupDirectory.appendingPathComponent("State/instances")
        
        guard FileManager.default.fileExists(atPath: instancesDirectory.path) else {
            logger.info("No instances directory found, starting fresh")
            return
        }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: instancesDirectory, includingPropertiesForKeys: nil)
            
            for file in files where file.pathExtension == "json" {
                if let state = try? appGroupManager.loadData(WidgetInstanceState.self, from: file) {
                    activeInstances[state.instanceId] = state
                }
            }
            
            logger.info("Loaded \(activeInstances.count) existing instances")
        } catch {
            logger.error("Failed to load existing instances: \(error.localizedDescription)")
        }
    }
}

// MARK: - Extension for Widget Configuration

extension WidgetInstanceManager {
    func getNextFrameIndex(for instanceId: String, totalFrames: Int) -> Int {
        guard let state = activeInstances[instanceId] else { return 0 }
        
        if !state.isAnimating {
            return state.currentFrameIndex
        }
        
        let nextFrame = (state.currentFrameIndex + 1) % totalFrames
        updateInstanceFrame(instanceId, frameIndex: nextFrame)
        
        return nextFrame
    }
    
    func resetInstanceAnimation(_ instanceId: String) {
        updateInstanceFrame(instanceId, frameIndex: 0)
    }
}

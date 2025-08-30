import Foundation
import SwiftUI
import WidgetKit
import SharedKit

// MARK: - Widget Data Service

@MainActor
class WidgetDataService: ObservableObject {
    static let shared = WidgetDataService()
    
    @Published var currentDesign: AnimationDesign?
    @Published var availableDesigns: [AnimationDesign] = []
    @Published var isLoading = false
    @Published var lastUpdateDate: Date?
    
    private let appStore = AppGroupStore.shared
    private let logger = SharedLogger.shared
    
    private init() {
        loadInitialData()
    }
    
    // MARK: - Public Methods
    
    func loadInitialData() {
        Task {
            await loadAvailableDesigns()
            await loadCurrentDesign()
        }
    }
    
    func updateCurrentDesign(_ design: AnimationDesign) async {
        isLoading = true
        
        do {
            // Create widget entry
            let widgetEntry = WidgetEntry(
                id: design.id,
                title: design.name,
                subtitle: "Animation",
                animationFrames: generateFrameNames(for: design),
                frameCount: design.frameCount,
                category: "animation",
                isFavorite: false,
                lastUpdated: Date()
            )
            
            // Save to App Group
            try appStore.writeJSON(widgetEntry, to: SharedConstants.currentWidgetDataFile)
            
            // Update UserDefaults
            UserDefaults.appGroup.currentWidgetDesignId = design.id
            UserDefaults.appGroup.lastWidgetUpdate = Date()
            
            // Update local state
            currentDesign = design
            lastUpdateDate = Date()
            
            // Reload widget
            WidgetCenter.shared.reloadTimelines(ofKind: SharedConstants.widgetKind)
            
            logger.info("Successfully updated widget with design: \(design.name)")
            
        } catch {
            logger.error("Failed to update widget design: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func loadAvailableDesigns() async {
        do {
            // Load from App Group if exists
            if appStore.fileExists(SharedConstants.availableDesignsFile) {
                availableDesigns = try appStore.readJSON([AnimationDesign].self, from: SharedConstants.availableDesignsFile)
                logger.info("Loaded \(availableDesigns.count) designs from App Group")
            } else {
                // Generate sample designs and save
                await generateSampleDesigns()
            }
        } catch {
            logger.error("Failed to load available designs: \(error.localizedDescription)")
            await generateSampleDesigns()
        }
    }
    
    func loadCurrentDesign() async {
        do {
            if appStore.fileExists(SharedConstants.currentWidgetDataFile) {
                let widgetEntry = try appStore.readJSON(WidgetEntry.self, from: SharedConstants.currentWidgetDataFile)
                currentDesign = availableDesigns.first { $0.id == widgetEntry.id }
                lastUpdateDate = widgetEntry.lastUpdated
                logger.info("Loaded current design: \(currentDesign?.name ?? "Unknown")")
            }
        } catch {
            logger.error("Failed to load current design: \(error.localizedDescription)")
        }
    }
    
    func refreshData() async {
        isLoading = true
        
        // Simulate network call delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        await loadAvailableDesigns()
        await loadCurrentDesign()
        
        // Update timestamp
        lastUpdateDate = Date()
        UserDefaults.appGroup.lastWidgetUpdate = Date()
        
        // Reload widget
        WidgetCenter.shared.reloadTimelines(ofKind: SharedConstants.widgetKind)
        
        isLoading = false
        logger.info("Data refresh completed")
    }
    
    // MARK: - Private Methods
    
    private func generateSampleDesigns() async {
        let sampleDesigns = [
            AnimationDesign(
                id: "manuelTest02",
                name: "Manuel Test Animation",
                podiumName: "Manuel Test Animation",
                frameCount: 24,
                frameRate: 10.0
            ),
            AnimationDesign(
                id: "sample_01",
                name: "Spinning Wheel",
                podiumName: "Manuel Test Animation",
                frameCount: 12,
                frameRate: 12.5
            ),
            AnimationDesign(
                id: "sample_02",
                name: "Pulse Effect",
                podiumName: "Manuel Test Animation",
                frameCount: 8,
                frameRate: 6.7
            )
        ]
        
        do {
            availableDesigns = sampleDesigns
            try appStore.writeJSON(sampleDesigns, to: SharedConstants.availableDesignsFile)
            logger.info("Generated and saved \(sampleDesigns.count) sample designs")
        } catch {
            logger.error("Failed to save sample designs: \(error.localizedDescription)")
        }
    }
    
    private func generateFrameNames(for design: AnimationDesign) -> [String] {
        return (1...design.frameCount).map { String(format: "\(design.id)_frame_%02d", $0) }
    }
}

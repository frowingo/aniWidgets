import WidgetKit
import SwiftUI
import AppIntents
import os.log
import SharedKit

private let widgetLogger = Logger(subsystem: "com.aniwidgets.logging", category: "Widget")

// MARK: - Shared Models and Managers (Widget Extension)
// Note: These are simplified versions for the widget extension
// The full versions are in the main app target

struct AppGroupManager {
    let appGroupId = "group.Iworf.aniWidgets"
    private let fileManager = FileManager.default
    
    private var appGroupDirectory: URL {
        guard let url = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            fatalError("App Group directory not found: \(appGroupId)")
        }
        return url
    }
    
    var featuredConfigPath: URL {
        return appGroupDirectory.appendingPathComponent("Config/featured.json")
    }
    
    func instanceStatePath(for instanceId: String) -> URL {
        return appGroupDirectory.appendingPathComponent("State/instances/\(instanceId).json")
    }
    
    func frameImagePath(for designId: String, frameIndex: Int) -> URL {
        let frameFileName = "frame_\(String(format: "%02d", frameIndex)).png"
        return appGroupDirectory.appendingPathComponent("Designs/\(designId)/frames/\(frameFileName)")
    }
    
    func loadData<T: Codable>(_ type: T.Type, from url: URL) throws -> T {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(type, from: data)
    }
    
    func saveData<T: Codable>(_ data: T, to url: URL) throws {
        let directory = url.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        }
        let jsonData = try JSONEncoder().encode(data)
        try jsonData.write(to: url)
    }
}

// MARK: - Widget Time Manager

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

// MARK: - Minimal Widget Instance Manager for Extension

struct WidgetInstanceManager {
    private let appGroupManager = AppGroupManager()
    
    func loadInstanceState(_ instanceId: String) -> WidgetInstanceState? {
        let statePath = appGroupManager.instanceStatePath(for: instanceId)
        
        do {
            let data = try Data(contentsOf: statePath)
            return try JSONDecoder().decode(WidgetInstanceState.self, from: data)
        } catch {
            return nil
        }
    }
    
    func createInstance(designId: String) -> String {
        let instanceId = UUID().uuidString
        let state = WidgetInstanceState(instanceId: instanceId, designId: designId)
        
        do {
            let statePath = appGroupManager.instanceStatePath(for: instanceId)
            let data = try JSONEncoder().encode(state)
            try data.write(to: statePath)
            return instanceId
        } catch {
            return instanceId
        }
    }
    
    func startAnimation(for instanceId: String) -> Bool {
        guard var state = loadInstanceState(instanceId) else { return false }
        
        state.isAnimating = true
        state.animationStartTime = Date()
        
        do {
            let statePath = appGroupManager.instanceStatePath(for: instanceId)
            let data = try JSONEncoder().encode(state)
            try data.write(to: statePath)
            return true
        } catch {
            return false
        }
    }
}

// MARK: - Widget Base Protocol

// MARK: - Widget Base Protocol
protocol FeaturedWidgetProtocol: Widget {
    var slotIndex: Int { get }
    var widgetKind: String { get }
    var displayName: String { get }
}

// MARK: - Widget Implementations
struct FeaturedWidgetSlotA: Widget, FeaturedWidgetProtocol {
    let slotIndex = 0
    let widgetKind = "FeaturedWidgetSlotA"
    let displayName = "Featured Design A"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: widgetKind, provider: FeaturedWidgetProvider(slotIndex: slotIndex)) { entry in
            FeaturedWidgetView(entry: entry, slotIndex: slotIndex)
        }
        .configurationDisplayName(displayName)
        .description("First featured animated design")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

struct FeaturedWidgetSlotB: Widget, FeaturedWidgetProtocol {
    let slotIndex = 1
    let widgetKind = "FeaturedWidgetSlotB"
    let displayName = "Featured Design B"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: widgetKind, provider: FeaturedWidgetProvider(slotIndex: slotIndex)) { entry in
            FeaturedWidgetView(entry: entry, slotIndex: slotIndex)
        }
        .configurationDisplayName(displayName)
        .description("Second featured animated design")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

struct FeaturedWidgetSlotC: Widget, FeaturedWidgetProtocol {
    let slotIndex = 2
    let widgetKind = "FeaturedWidgetSlotC"
    let displayName = "Featured Design C"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: widgetKind, provider: FeaturedWidgetProvider(slotIndex: slotIndex)) { entry in
            FeaturedWidgetView(entry: entry, slotIndex: slotIndex)
        }
        .configurationDisplayName(displayName)
        .description("Third featured animated design")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

struct FeaturedWidgetSlotD: Widget, FeaturedWidgetProtocol {
    let slotIndex = 3
    let widgetKind = "FeaturedWidgetSlotD"
    let displayName = "Featured Design D"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: widgetKind, provider: FeaturedWidgetProvider(slotIndex: slotIndex)) { entry in
            FeaturedWidgetView(entry: entry, slotIndex: slotIndex)
        }
        .configurationDisplayName(displayName)
        .description("Fourth featured animated design")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

// MARK: - Timeline Provider
struct FeaturedWidgetProvider: TimelineProvider {
    typealias Entry = FeaturedWidgetEntry
    let slotIndex: Int
    private let appGroupManager = AppGroupManager()
    private let appStore = AppGroupStore.shared
    private let logger = SharedLogger.shared
    
    func placeholder(in context: Context) -> FeaturedWidgetEntry {
        FeaturedWidgetEntry(
            date: Date(),
            slotIndex: slotIndex,
            designId: nil,
            frameIndex: 1,
            instanceId: UUID().uuidString,
            isAnimating: false
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (FeaturedWidgetEntry) -> ()) {
        // Try to load current widget data from App Group
        let designId = loadCurrentWidgetDesignId() ?? getFeaturedDesignId(for: slotIndex)
        
        let entry = FeaturedWidgetEntry(
            date: Date(),
            slotIndex: slotIndex,
            designId: designId,
            frameIndex: 1,
            instanceId: UUID().uuidString,
            isAnimating: false
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<FeaturedWidgetEntry>) -> ()) {
        logger.info("📊 Timeline requested for slot \(slotIndex)")
        
        // Try to load from App Group first, then fallback to featured design
        let designId = loadCurrentWidgetDesignId() ?? getFeaturedDesignId(for: slotIndex)
        
        guard let designId = designId else {
            // No design for this slot
            let entry = FeaturedWidgetEntry(
                date: Date(),
                slotIndex: slotIndex,
                designId: nil,
                frameIndex: 1,
                instanceId: UUID().uuidString,
                isAnimating: false
            )
            let timeline = Timeline(entries: [entry], policy: .never)
            completion(timeline)
            return
        }
        
        // Create or get instance for this widget
        let instanceId = getOrCreateInstanceId(for: context, designId: designId)
        let instanceManager = WidgetInstanceManager()
        
        if let instanceState = instanceManager.loadInstanceState(instanceId) {
            if instanceState.isAnimating, let startTime = instanceState.animationStartTime {
                // Generate animation timeline
                let entries = generateAnimationTimeline(
                    startTime: startTime,
                    designId: designId,
                    instanceId: instanceId,
                    slotIndex: slotIndex
                )
                let timeline = Timeline(entries: entries, policy: .atEnd)
                completion(timeline)
            } else {
                // Static entry
                let entry = FeaturedWidgetEntry(
                    date: Date(),
                    slotIndex: slotIndex,
                    designId: designId,
                    frameIndex: instanceState.currentFrame,
                    instanceId: instanceId,
                    isAnimating: false
                )
                let timeline = Timeline(entries: [entry], policy: .never)
                completion(timeline)
            }
        } else {
            // Create new instance
            let newInstanceId = instanceManager.createInstance(designId: designId)
            let entry = FeaturedWidgetEntry(
                date: Date(),
                slotIndex: slotIndex,
                designId: designId,
                frameIndex: 1,
                instanceId: newInstanceId,
                isAnimating: false
            )
            let timeline = Timeline(entries: [entry], policy: .never)
            completion(timeline)
        }
    }
    
    private func loadCurrentWidgetDesignId() -> String? {
        do {
            if appStore.fileExists(SharedConstants.currentWidgetDataFile) {
                let widgetData = try appStore.readJSON(WidgetEntry.self, from: SharedConstants.currentWidgetDataFile)
                logger.info("Loaded current widget design from App Group: \(widgetData.id)")
                return widgetData.id
            }
        } catch {
            logger.error("Failed to load current widget data from App Group: \(error.localizedDescription)")
        }
        return nil
    }
    
    private func getFeaturedDesignId(for slotIndex: Int) -> String? {
        do {
            let featuredConfig = try appGroupManager.loadData(FeaturedConfig.self, from: appGroupManager.featuredConfigPath)
            return slotIndex < featuredConfig.designs.count ? featuredConfig.designs[slotIndex] : nil
        } catch {
            widgetLogger.warning("⚠️ Could not load featured config: \(error)")
            return nil
        }
    }
    
    private func getOrCreateInstanceId(for context: Context, designId: String) -> String {
        // In a real implementation, you'd use context.family and other identifiers
        // to create a unique instance ID for each widget placement
        // For now, we'll use a simple approach
        let instanceKey = "widget_slot_\(slotIndex)_instance"
        let userDefaults = UserDefaults(suiteName: appGroupManager.appGroupId)
        
        if let existingInstanceId = userDefaults?.string(forKey: instanceKey) {
            return existingInstanceId
        } else {
            let newInstanceId = WidgetInstanceManager().createInstance(designId: designId)
            userDefaults?.set(newInstanceId, forKey: instanceKey)
            return newInstanceId
        }
    }
    
    private func generateAnimationTimeline(
        startTime: Date,
        designId: String,
        instanceId: String,
        slotIndex: Int
    ) -> [FeaturedWidgetEntry] {
        var entries: [FeaturedWidgetEntry] = []
        let currentDate = Date()
        let frameInterval: Double = 0.5
        let totalFrames = 24
        
        for i in 1...totalFrames {
            let entryDate = startTime.addingTimeInterval(Double(i - 1) * frameInterval)
            if entryDate > currentDate {
                let entry = FeaturedWidgetEntry(
                    date: entryDate,
                    slotIndex: slotIndex,
                    designId: designId,
                    frameIndex: i,
                    instanceId: instanceId,
                    isAnimating: true
                )
                entries.append(entry)
            }
        }
        
        // Reset entry at the end
        let resetDate = startTime.addingTimeInterval(Double(totalFrames) * frameInterval + 1.0)
        if resetDate > currentDate {
            let resetEntry = FeaturedWidgetEntry(
                date: resetDate,
                slotIndex: slotIndex,
                designId: designId,
                frameIndex: 1,
                instanceId: instanceId,
                isAnimating: false
            )
            entries.append(resetEntry)
        }
        
        return entries
    }
}

// MARK: - Widget Entry
struct FeaturedWidgetEntry: TimelineEntry {
    let date: Date
    let slotIndex: Int
    let designId: String?
    let frameIndex: Int
    let instanceId: String
    let isAnimating: Bool
}

// MARK: - Widget View
struct FeaturedWidgetView: View {
    let entry: FeaturedWidgetEntry
    let slotIndex: Int
    
    var body: some View {
        ZStack {
            if let designId = entry.designId {
                // Full-screen design view
                DesignFrameView(
                    designId: designId,
                    frameIndex: entry.frameIndex
                )
                
                // Invisible button covering entire widget
                Button(intent: StartAnimationIntent(instanceId: entry.instanceId)) {
                    Color.clear
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
            } else {
                // Empty slot
                EmptySlotView(slotIndex: slotIndex)
            }
        }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .containerBackground(.clear, for: .widget)
    }
}

struct DesignFrameView: View {
    let designId: String
    let frameIndex: Int
    private let appGroupManager = AppGroupManager()
    
    var body: some View {
        if let frameImage = loadFrameImage() {
            Image(uiImage: frameImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea(.all)
        } else if designId == "test01" {
            // Fallback to bundle asset for test01
            Image("frame_\(String(format: "%02d", frameIndex))")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea(.all)
        } else {
            // Placeholder for other designs
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all)
                .overlay(
                    VStack(spacing: 4) {
                        Text(designId)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                        
                        Text("Frame \(frameIndex)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                )
        }
    }
    
    private func loadFrameImage() -> UIImage? {
        // First try App Group path (for downloaded designs)
        let framePath = appGroupManager.frameImagePath(for: designId, frameIndex: frameIndex)
        
        if FileManager.default.fileExists(atPath: framePath.path) {
            return UIImage(contentsOfFile: framePath.path)
        }
        
        // Try bundle test design path (for TestDesigns folder)
        if let bundleFrameImage = loadFromBundleTestDesigns() {
            return bundleFrameImage
        }
        
        return nil
    }
    
    private func loadFromBundleTestDesigns() -> UIImage? {
        // Look for TestDesigns/{designId}/frame_{frameIndex}.png
        guard let bundlePath = Bundle.main.path(forResource: "TestDesigns/\(designId)/frame_\(String(format: "%02d", frameIndex))", ofType: "png") else {
            return nil
        }
        
        return UIImage(contentsOfFile: bundlePath)
    }
}

struct EmptySlotView: View {
    let slotIndex: Int
    
    private var slotName: String {
        ["A", "B", "C", "D"][slotIndex]
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "rectangle.dashed")
                .font(.system(size: 24))
                .foregroundColor(.gray)
            
            Text("Slot \(slotName)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Add design in app")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGray6))
        .ignoresSafeArea(.all)
    }
}

// MARK: - App Intent
struct StartAnimationIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Animation"
    static let description = IntentDescription("Start widget animation")
    
    @Parameter(title: "Instance ID")
    var instanceId: String
    
    init() {
        self.instanceId = ""
    }
    
    init(instanceId: String) {
        self.instanceId = instanceId
    }
    
    func perform() async throws -> some IntentResult {
        widgetLogger.info("🎬 StartAnimationIntent for instance: \(instanceId)")
        
        let instanceManager = WidgetInstanceManager()
        let success = instanceManager.startAnimation(for: instanceId)
        
        if success {
            WidgetCenter.shared.reloadAllTimelines()
            widgetLogger.info("✅ Animation started for instance: \(instanceId)")
        } else {
            widgetLogger.error("❌ Failed to start animation for instance: \(instanceId)")
        }
        
        return .result()
    }
}

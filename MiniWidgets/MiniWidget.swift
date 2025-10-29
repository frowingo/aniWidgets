import WidgetKit
import SwiftUI
import AppIntents
import os.log
import SharedKit

private let widgetLogger = Logger(subsystem: "com.aniwidgets.logging", category: "Widget")

// MARK: - Shared Models and Managers (Widget Extension)
// Note: These are simplified versions for the widget extension
// The full versions are in the main app target

// AppGroupManager Widget extension version - using SharedKit
// Note: Using SharedKit.AppGroupManager instead of local implementation

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
    private let appGroupManager = AppGroupManager.shared
    
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
        guard var state = loadInstanceState(instanceId) else {
            return false
        }
        
        // If already animating, ignore this request
        if state.isAnimating {
            return false
        }
        
        // Reset animation to start from frame 1
        state.isAnimating = true
        state.currentFrame = 1
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
    private let appGroupManager = AppGroupManager.shared
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
        
        // Debug: Check if frames exist in App Group
        _ = appGroupManager.frameImagePath(for: designId, frameIndex: 1)
        
        // Create or get instance for this widget
        let instanceId = getOrCreateInstanceId(for: context, designId: designId)
        let instanceManager = WidgetInstanceManager()
        
        if let instanceState = instanceManager.loadInstanceState(instanceId) {
            
            // Simple frame-based animation system
            let frameIndex = getNextFrameForWidget(instanceId: instanceId, designId: designId)
            
            // Re-load instance state after frame update to get current isAnimating status
            let updatedInstanceState = instanceManager.loadInstanceState(instanceId) ?? instanceState
            
            let entry = FeaturedWidgetEntry(
                date: Date(),
                slotIndex: slotIndex,
                designId: designId,
                frameIndex: frameIndex,
                instanceId: instanceId,
                isAnimating: updatedInstanceState.isAnimating
            )
            
            // Use hybrid manual chain for animation
            let timeline: Timeline<FeaturedWidgetEntry>
            
            if updatedInstanceState.isAnimating {
                let totalFrames = getFrameCount(for: designId)
                
                // Check if we need to continue animation
                if frameIndex < totalFrames {
                    // Schedule next frame reload manually after 0.15 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        
                        // getWidgetKind()
                        let appGroupManager = AppGroupManager.shared
                        let userDefaults = UserDefaults(suiteName: appGroupManager.appGroupId)
                        
                        let slotKeys = [
                            "widget_slot_0_instance": "FeaturedWidgetSlotA",
                            "widget_slot_1_instance": "FeaturedWidgetSlotB",
                            "widget_slot_2_instance": "FeaturedWidgetSlotC",
                            "widget_slot_3_instance": "FeaturedWidgetSlotD"
                        ]
                        
                        var targetWidgetKind: String?
                        for (key, widgetKind) in slotKeys {
                            let storedInstanceId = userDefaults?.string(forKey: key)
                            if storedInstanceId == instanceId {
                                targetWidgetKind = widgetKind
                                break
                            }
                        }
                        
                        if let widgetKind = targetWidgetKind {
                            WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
                        }
                    }
                }
                
                // Create timeline with .never policy (manual reload handles timing)
                timeline = Timeline(entries: [entry], policy: .never)
            } else {
                // Animation stopped - no more reloads
                timeline = Timeline(entries: [entry], policy: .never)
            }
            
            completion(timeline)
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
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(300)))
            completion(timeline)
        }
    }
    
    private func loadCurrentWidgetDesignId() -> String? {
        do {
            if appStore.fileExists(SharedConstants.currentWidgetDataFile) {
                let widgetData = try appStore.readJSON(WidgetEntry.self, from: SharedConstants.currentWidgetDataFile)
                return widgetData.id
            }
        } catch {
        }
        return nil
    }
    
    private func getFeaturedDesignId(for slotIndex: Int) -> String? {
        do {
            let featuredConfig = try appGroupManager.loadData(FeaturedConfig.self, from: appGroupManager.featuredConfigPath)
            
            if slotIndex < featuredConfig.designs.count {
                let designId = featuredConfig.designs[slotIndex]
                return designId
            } else {
                return nil
            }
        } catch {
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
            // Mevcut instance'ın designId'sini kontrol et ve gerekirse güncelle
            let instanceManager = WidgetInstanceManager()
            if var existingState = instanceManager.loadInstanceState(existingInstanceId) {
                if existingState.designId != designId {
                    
                    existingState.designId = designId
                    do {
                        let statePath = appGroupManager.instanceStatePath(for: existingInstanceId)
                        let data = try JSONEncoder().encode(existingState)
                        try data.write(to: statePath)
                    } catch {
                    }
                }
            }
            return existingInstanceId
        } else {
            let newInstanceId = WidgetInstanceManager().createInstance(designId: designId)
            userDefaults?.set(newInstanceId, forKey: instanceKey)
            return newInstanceId
        }
    }
    
    private func getFrameCount(for designId: String) -> Int {
        // Safety check for design ID
        guard !designId.isEmpty else {
            return 1
        }
        
        var frameCount = 0
        for i in 1...60 {
            let framePath = appGroupManager.frameImagePath(for: designId, frameIndex: i)
            if FileManager.default.fileExists(atPath: framePath.path) {
                frameCount = i
            } else {
                break
            }
        }
        
        // Ensure at least 1 frame (fallback)
        let finalFrameCount = max(frameCount, 1)
        return finalFrameCount
    }
    
    private func getNextFrameForWidget(instanceId: String, designId: String) -> Int {
        let instanceManager = WidgetInstanceManager()
        
        if let state = instanceManager.loadInstanceState(instanceId) {
            if state.isAnimating {
                let totalFrames = getFrameCount(for: designId)
                
                // If we've shown all frames, stop animation and stay on first frame
                if state.currentFrame >= totalFrames {
                    var updatedState = state
                    updatedState.isAnimating = false
                    updatedState.currentFrame = 1
                    
                    do {
                        let statePath = appGroupManager.instanceStatePath(for: instanceId)
                        let data = try JSONEncoder().encode(updatedState)
                        try data.write(to: statePath)
                    } catch {
                    }
                    
                    return 1
                }
                
                let nextFrame = state.currentFrame + 1
                
                var updatedState = state
                updatedState.currentFrame = nextFrame
                
                do {
                    let statePath = appGroupManager.instanceStatePath(for: instanceId)
                    let data = try JSONEncoder().encode(updatedState)
                    try data.write(to: statePath)
                } catch {
                }
                
                return nextFrame
            } else {
                return state.currentFrame
            }
        }
        
        return 1 // Default first frame
    }
}

struct FeaturedWidgetEntry: TimelineEntry {
    let date: Date
    let slotIndex: Int
    let designId: String?
    let frameIndex: Int
    let instanceId: String
    let isAnimating: Bool
    
    // Add unique identifier for each entry to help SwiftUI detect changes
    var id: String {
        return "\(instanceId)_\(frameIndex)_\(Int(date.timeIntervalSince1970))"
    }
}

struct FeaturedWidgetView: View {
    let entry: FeaturedWidgetEntry
    let slotIndex: Int
    
    // Remove internal state - use only timeline entry data
    
    // Initialize from entry only
    init(entry: FeaturedWidgetEntry, slotIndex: Int) {
        self.entry = entry
        self.slotIndex = slotIndex
    }
    
    var body: some View {
        ZStack {
            if let designId = entry.designId {
                // Use DesignFrameView with timeline entry data directly - NO INTERNAL STATE!
                DesignFrameView(designId: designId, frameIndex: entry.frameIndex)
                    .id(entry.instanceId) // Stable ID per widget instance, not per frame
                
                // Invisible button covering entire widget
                Button(intent: StartAnimationIntent(instanceId: entry.instanceId)) {
                    Color.clear
                }
                .buttonStyle(InvisibleButtonStyle())
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
    private let appGroupManager = AppGroupManager.shared
    
    var body: some View {
        Group {
            if let frameImage = loadFrameImage() {
                Image(uiImage: frameImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .ignoresSafeArea(.all)
            } else {
                // Try SwiftUI Image for Assets.xcassets
                let assetName = "\(designId)_frame_\(String(format: "%02d", frameIndex))"
                
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                    
                    Text(designId)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Frame \(frameIndex)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Loading...")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGray6))
                .ignoresSafeArea(.all)
                .onAppear {
                }
            }
        }
        .onAppear {
        }
    }
    
    private func loadFrameImage() -> UIImage? {
        
        
        // Primary: Try Bundle Cache first (much faster for widgets)
        let imageName = "frame_\(String(format: "%02d", frameIndex))"
        
        if let bundleImage = appGroupManager.loadImageFromBundleCache(named: imageName, designFolder: designId) {
            let resizedImage = resizeImageForWidget(bundleImage)
            
            return resizedImage
        }
        
        // Secondary: Try App Group path (frameIndex is 1-based, but frameImagePath expects 0-based)
        let framePath = appGroupManager.frameImagePath(for: designId, frameIndex: frameIndex - 1)
        
        
        if FileManager.default.fileExists(atPath: framePath.path) {
            
            if let originalImage = UIImage(contentsOfFile: framePath.path) {
                let resizedImage = resizeImageForWidget(originalImage)
                
                return resizedImage
            } else {
                
            }
        } else {
            
        }
        
        // Fallback: Try Assets.xcassets with exact naming convention
        let assetName = "\(designId)_frame_\(String(format: "%02d", frameIndex))"
        
        if let bundleImage = UIImage(named: assetName) {
            let resizedImage = resizeImageForWidget(bundleImage)
            
            return resizedImage
        }
        
        // Final fallback: Try generic frame names
        let genericAssetName = "frame_\(String(format: "%02d", frameIndex))"
        
        if let genericImage = UIImage(named: genericAssetName) {
            let resizedImage = resizeImageForWidget(genericImage)
            
            return resizedImage
        }
        
        return nil
    }
    
    private func resizeImageForWidget(_ image: UIImage) -> UIImage {
        let targetSize = CGSize(width: 300, height: 300)
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage ?? image
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

// MARK: - Custom Button Style
struct InvisibleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(1.0) // No scale on press
            .opacity(1.0)     // No opacity change on press
            .background(Color.clear)
            .foregroundColor(Color.clear)
            .animation(.none, value: configuration.isPressed) // No animation on press
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
        
        // Directly use the widget extension's instance manager
        let widgetManager = WidgetInstanceManager()
        
        // Manually trigger animation by setting state and reloading timeline
        if var state = widgetManager.loadInstanceState(instanceId) {
            if !state.isAnimating {
                state.isAnimating = true
                state.currentFrame = 1
                state.animationStartTime = Date()
                
                // Save updated state
                do {
                    let appGroupManager = AppGroupManager.shared
                    let statePath = appGroupManager.instanceStatePath(for: instanceId)
                    let data = try JSONEncoder().encode(state)
                    try data.write(to: statePath)
                    
                    // Reload only the specific widget that was tapped
                    if let widgetKind = getWidgetKind(for: instanceId) {
                        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
                    } else {
                        WidgetCenter.shared.reloadAllTimelines() // Fallback
                    }
                } catch {
                }
            }
        }
        
        return .result()
    }
    
    private func getWidgetKind(for instanceId: String) -> String? {
        // Check UserDefaults to find which slot this instance belongs to
        let appGroupManager = AppGroupManager.shared
        let userDefaults = UserDefaults(suiteName: appGroupManager.appGroupId)
        
        let slotKeys = [
            "widget_slot_0_instance": "FeaturedWidgetSlotA",
            "widget_slot_1_instance": "FeaturedWidgetSlotB",
            "widget_slot_2_instance": "FeaturedWidgetSlotC",
            "widget_slot_3_instance": "FeaturedWidgetSlotD"
        ]
        
        for (key, widgetKind) in slotKeys {
            let storedInstanceId = userDefaults?.string(forKey: key)
            
            if storedInstanceId == instanceId {
                return widgetKind
            }
        }
        
        return nil
    }
}

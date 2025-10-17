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
        logger.info("📊 Timeline requested for slot \(slotIndex)")
        
        // Debug App Group access
        logger.info("🔍 Widget Debug: App Group ID = \(appGroupManager.appGroupId)")
        logger.info("🔍 Widget Debug: App Group Directory = \(appGroupManager.appGroupDirectory.path)")
        
        // Try to load from App Group first, then fallback to featured design
        let designId = loadCurrentWidgetDesignId() ?? getFeaturedDesignId(for: slotIndex)
        
        guard let designId = designId else {
            logger.warning("⚠️ No design found for slot \(slotIndex)")
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
        
        logger.info("✅ Using design \(designId) for slot \(slotIndex)")
        
        // Debug: Check if frames exist in App Group
        let testFramePath = appGroupManager.frameImagePath(for: designId, frameIndex: 1)
        logger.info("🔍 Widget Debug: Test frame path = \(testFramePath.path)")
        logger.info("🔍 Widget Debug: Frame exists = \(FileManager.default.fileExists(atPath: testFramePath.path))")
        
        // Create or get instance for this widget
        let instanceId = getOrCreateInstanceId(for: context, designId: designId)
        let instanceManager = WidgetInstanceManager()
        
        logger.info("🔍 Widget: Using instance ID: \(instanceId)")
        
        if let instanceState = instanceManager.loadInstanceState(instanceId) {
            logger.info("✅ Widget: Loaded existing instance state - frame: \(instanceState.currentFrame), animating: \(instanceState.isAnimating)")
            
            if instanceState.isAnimating, let startTime = instanceState.animationStartTime {
                // Check if animation should still be running
                let currentDate = Date()
                let animationDuration: TimeInterval = 24 * 0.5 + 1.0 // 24 frames * 0.5s + 1s buffer
                let animationEndTime = startTime.addingTimeInterval(animationDuration)
                
                if currentDate < animationEndTime {
                    // Animation still active
                    let entries = generateAnimationTimeline(
                        startTime: startTime,
                        designId: designId,
                        instanceId: instanceId,
                        slotIndex: slotIndex
                    )
                    let timeline = Timeline(entries: entries, policy: .atEnd)
                    logger.info("🎬 Widget: Timeline completed for slot \(slotIndex) with \(entries.count) animation entries")
                    completion(timeline)
                } else {
                    // Animation finished, reset to static
                    logger.info("⏰ Widget: Animation expired, resetting to static state")
                    var updatedState = instanceState
                    updatedState.isAnimating = false
                    updatedState.animationStartTime = nil
                    updatedState.currentFrame = 1
                    
                    // Save updated state
                    do {
                        let statePath = appGroupManager.instanceStatePath(for: instanceId)
                        let data = try JSONEncoder().encode(updatedState)
                        try data.write(to: statePath)
                    } catch {
                        logger.error("Failed to update instance state: \(error)")
                    }
                    
                    // Create static entry
                    let entry = FeaturedWidgetEntry(
                        date: Date(),
                        slotIndex: slotIndex,
                        designId: designId,
                        frameIndex: 1,
                        instanceId: instanceId,
                        isAnimating: false
                    )
                    logger.info("📌 Widget: Creating static entry after animation reset")
                    let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(300)))
                    logger.info("🎬 Widget: Timeline completed for slot \(slotIndex) with static entry (post-animation)")
                    completion(timeline)
                }
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
                logger.info("📌 Widget: Creating static entry for \(designId) frame \(instanceState.currentFrame)")
                let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(300))) // Refresh in 5 minutes
                logger.info("🎬 Widget: Timeline completed for slot \(slotIndex) with static entry")
                completion(timeline)
            }
        } else {
            // Create new instance
            logger.info("⚠️ Widget: No existing instance found, creating new one")
            let newInstanceId = instanceManager.createInstance(designId: designId)
            logger.info("✅ Widget: Created new instance: \(newInstanceId)")
            
            let entry = FeaturedWidgetEntry(
                date: Date(),
                slotIndex: slotIndex,
                designId: designId,
                frameIndex: 1,
                instanceId: newInstanceId,
                isAnimating: false
            )
            logger.info("📌 Widget: Creating new instance entry for \(designId) frame 1")
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(300))) // Refresh in 5 minutes
            logger.info("🎬 Widget: Timeline completed for slot \(slotIndex) with new instance")
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
            logger.info("🔍 Widget: Loading featured config for slot \(slotIndex)")
            let featuredConfig = try appGroupManager.loadData(FeaturedConfig.self, from: appGroupManager.featuredConfigPath)
            logger.info("✅ Widget: Loaded featured config with \(featuredConfig.designs.count) designs: \(featuredConfig.designs)")
            
            if slotIndex < featuredConfig.designs.count {
                let designId = featuredConfig.designs[slotIndex]
                logger.info("✅ Widget: Selected design \(designId) for slot \(slotIndex)")
                return designId
            } else {
                logger.warning("⚠️ Widget: Slot index \(slotIndex) exceeds featured designs count (\(featuredConfig.designs.count))")
                return nil
            }
        } catch {
            logger.error("❌ Widget: Could not load featured config: \(error.localizedDescription)")
            logger.error("❌ Widget: Featured config path: \(appGroupManager.featuredConfigPath.path)")
            logger.error("❌ Widget: File exists: \(FileManager.default.fileExists(atPath: appGroupManager.featuredConfigPath.path))")
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
        
        // If animation start time is in the past, start from now
        let actualStartTime = max(startTime, currentDate)
        logger.info("🎬 Widget: Animation timeline - originalStart: \(startTime), actualStart: \(actualStartTime), current: \(currentDate)")
        
        for i in 1...totalFrames {
            let entryDate = actualStartTime.addingTimeInterval(Double(i - 1) * frameInterval)
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
        
        // Reset entry at the end
        let resetDate = actualStartTime.addingTimeInterval(Double(totalFrames) * frameInterval + 1.0)
        let resetEntry = FeaturedWidgetEntry(
            date: resetDate,
            slotIndex: slotIndex,
            designId: designId,
            frameIndex: 1,
            instanceId: instanceId,
            isAnimating: false
        )
        entries.append(resetEntry)
        
        logger.info("🎬 Widget: Generated \(entries.count) timeline entries")
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
                    .onAppear {
                        widgetLogger.info("✅ Widget View: Successfully displayed image for \(designId) frame \(frameIndex)")
                    }
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
                    widgetLogger.error("❌ Widget View: Failed to load image, showing placeholder for \(designId) frame \(frameIndex)")
                }
            }
        }
        .onAppear {
            widgetLogger.info("👀 Widget View: DesignFrameView appeared for \(designId) frame \(frameIndex)")
        }
    }
    
    private func loadFrameImage() -> UIImage? {
        widgetLogger.info("🔍 Widget: Loading frame for \(designId) index \(frameIndex)")
        
        // Primary: Try App Group path
        let framePath = appGroupManager.frameImagePath(for: designId, frameIndex: frameIndex)
        widgetLogger.info("🔍 Widget: Checking App Group path: \(framePath.path)")
        
        if FileManager.default.fileExists(atPath: framePath.path) {
            widgetLogger.info("✅ Widget: Found in App Group: \(framePath.lastPathComponent)")
            if let originalImage = UIImage(contentsOfFile: framePath.path) {
                // Resize image for widget constraints
                let resizedImage: UIImage = resizeImageForWidget(originalImage)
                widgetLogger.info("✅ Widget: Successfully loaded and resized image from App Group")
                let originalSize: CGSize = originalImage.size
                let resizedSize: CGSize = resizedImage.size
                
                return resizedImage
            } else {
                widgetLogger.error("❌ Widget: File exists but failed to load as UIImage")
            }
        } else {
            widgetLogger.warning("⚠️ Widget: Not found in App Group: \(framePath.lastPathComponent)")
            widgetLogger.warning("⚠️ Widget: App Group path: \(framePath.path)")
            
            // Debug: List contents of parent directory
            let parentDir = framePath.deletingLastPathComponent()
            if FileManager.default.fileExists(atPath: parentDir.path) {
                do {
                    let contents = try FileManager.default.contentsOfDirectory(atPath: parentDir.path)
                    widgetLogger.info("📋 Widget: Contents of frames directory: \(contents)")
                } catch {
                    widgetLogger.error("❌ Widget: Failed to list frames directory: \(error)")
                }
            } else {
                widgetLogger.warning("⚠️ Widget: Frames directory doesn't exist: \(parentDir.path)")
            }
        }
        
        // Fallback: Try Assets.xcassets with exact naming convention
        let assetName = "\(designId)_frame_\(String(format: "%02d", frameIndex))"
        widgetLogger.info("🎨 Widget: Trying Assets.xcassets: \(assetName)")
        if let bundleImage = UIImage(named: assetName) {
            let resizedImage: UIImage = resizeImageForWidget(bundleImage)
            widgetLogger.info("✅ Widget: Found and resized from Assets.xcassets: \(assetName)")
            return resizedImage
        } else {
            widgetLogger.warning("⚠️ Widget: Not found in Assets.xcassets: \(assetName)")
        }
        
        // Alternative fallback: Try generic frame names 
        let genericAssetName = "frame_\(String(format: "%02d", frameIndex))"
        widgetLogger.info("🎨 Widget: Trying generic Assets.xcassets: \(genericAssetName)")
        if let genericImage = UIImage(named: genericAssetName) {
            let resizedImage: UIImage = resizeImageForWidget(genericImage)
            widgetLogger.info("✅ Widget: Found and resized generic frame: \(genericAssetName)")
            return resizedImage
        } else {
            widgetLogger.warning("⚠️ Widget: Generic frame not found: \(genericAssetName)")
        }
        
        widgetLogger.error("❌ Widget: No frame found for \(designId) index \(frameIndex)")
        return nil
    }
    
    private func resizeImageForWidget(_ image: UIImage) -> UIImage {
        // Widget için güvenli maksimum boyut (square widget için)
        let maxWidgetSize: CGFloat = 300 // 300x300 = 90,000 pixels (well under the limit)
        
        let originalSize = image.size
        
        // If image is already small enough, return as-is
        if originalSize.width <= maxWidgetSize && originalSize.height <= maxWidgetSize {
            return image
        }
        
        // Calculate scale factor to fit within max size while maintaining aspect ratio
        let scaleFactor = min(maxWidgetSize / originalSize.width, maxWidgetSize / originalSize.height)
        let newSize = CGSize(width: originalSize.width * scaleFactor, height: originalSize.height * scaleFactor)
        
        // Use UIGraphicsImageRenderer for modern image resizing
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return resizedImage
    }
    
//    private func loadFromBundleTestDesigns() -> UIImage? {
//        // Look for TestDesigns/{designId}/{designId}_frame_{frameIndex}.png
//        guard let bundlePath = Bundle.main.path(forResource: "TestDesigns/\(designId)/\(designId)_frame_\(String(format: "%02d", frameIndex))", ofType: "png") else {
//            widgetLogger.error("❌ Widget: TestDesigns not found for \(designId) frame \(frameIndex)")
//            return nil
//        }
//        
//        widgetLogger.info("✅ Widget: Found TestDesigns frame at \(bundlePath)")
//        return UIImage(contentsOfFile: bundlePath)
//    }
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

import WidgetKit
import SwiftUI
import AppIntents
import os.log

private let widgetLogger = Logger(subsystem: "com.aniwidgets.logging", category: "Widget")

struct AnimatedFrameWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "AnimatedFrameWidget", provider: AppProvider()) { entry in
            WidgetView(entry: entry)
        }
        .configurationDisplayName("Animated Frame Widget")
        .description("Tıkla animasyon oyna")
        .supportedFamilies([.systemSmall])
    }
}

struct AppProvider: TimelineProvider {
    func placeholder(in context: Context) -> AppEntry {
        AppEntry(date: Date(), frameIndex: 1)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (AppEntry) -> ()) {
        let entry = AppEntry(date: Date(), frameIndex: 1)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        widgetLogger.info("📊 Timeline istendi")
        
        let userDefaults = UserDefaults(suiteName: "group.Iworf.aniWidgets")
        let currentFrame = userDefaults?.integer(forKey: "currentFrame") ?? 1
        
        widgetLogger.info("📊 Mevcut frame: \(currentFrame)")
        
        let entry = AppEntry(date: Date(), frameIndex: currentFrame)
        let timeline = Timeline(entries: [entry], policy: .never)
        
        completion(timeline)
    }
}

struct AppEntry: TimelineEntry {
    let date: Date
    let frameIndex: Int
}

struct WidgetView: View {
    var entry: AppEntry
    
    var body: some View {
        Button(intent: FrameAnimationIntent()) {
            Image("frame_\(String(format: "%02d", entry.frameIndex == 0 ? 1 : entry.frameIndex))")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .clipShape(Rectangle())
        .padding(-16)
    }
}

struct FrameAnimationIntent: AppIntent {
    static let title: LocalizedStringResource = "Animate Frame"
    static let description = IntentDescription("Animate the frame sequence")
    
    func perform() async throws -> some IntentResult {
        widgetLogger.info("🎬 FrameAnimationIntent başlatıldı")
        
        let userDefaults = UserDefaults(suiteName: "group.Iworf.aniWidgets")
        
        let frameCount = 24
        let timings = [
            0.7, 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.4,
            1.3, 1.2, 1.1, 1.0, 0.9, 0.8, 0.7, 0.8, 0.9, 1.0,
            1.1, 1.2, 1.3, 1.4
        ]
        
        widgetLogger.info("🎬 Animasyon başlıyor - \(frameCount) frame")
        
        for i in 1...frameCount {
            try await Task.sleep(nanoseconds: UInt64(timings[i-1] * 1_000_000_000))
            
            userDefaults?.set(i, forKey: "currentFrame")
            userDefaults?.synchronize()
            
            widgetLogger.info("🎬 Frame \(i) ayarlandı, timing: \(timings[i-1])s")
            
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        // Son olarak frame 1'e dön
        try await Task.sleep(nanoseconds: UInt64(1.5 * 1_000_000_000))
        userDefaults?.set(1, forKey: "currentFrame")
        userDefaults?.synchronize()
        
        widgetLogger.info("🎬 Animasyon tamamlandı, frame 1'e dönüldü")
        
        WidgetCenter.shared.reloadAllTimelines()
        
        return .result()
    }
}

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
        AppEntry(date: Date(), frameIndex: 1, isAnimating: false)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (AppEntry) -> ()) {
        let entry = AppEntry(date: Date(), frameIndex: 1, isAnimating: false)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<AppEntry>) -> ()) {
        widgetLogger.info("📊 Timeline istendi")
        
        let userDefaults = UserDefaults(suiteName: "group.Iworf.aniWidgets")
        let currentFrame = userDefaults?.integer(forKey: "currentFrame") ?? 1
        let isAnimating = userDefaults?.bool(forKey: "isAnimating") ?? false
        let animationStartTime = userDefaults?.object(forKey: "animationStartTime") as? Date
        
        widgetLogger.info("📊 Mevcut frame: \(currentFrame), Animating: \(isAnimating)")
        
        var entries: [AppEntry] = []
        let currentDate = Date()
        
        if isAnimating, let startTime = animationStartTime {
            // Animasyon devam ediyor - sonraki frame'leri oluştur
            let frameInterval: Double = 0.5
            let totalFrames = 24
            
            for i in 1...totalFrames {
                let entryDate = startTime.addingTimeInterval(Double(i - 1) * frameInterval)
                if entryDate > currentDate {
                    let entry = AppEntry(date: entryDate, frameIndex: i, isAnimating: true)
                    entries.append(entry)
                }
            }
            
            // Animasyon bitince frame 1'e dön ve animasyonu durdur
            let resetDate = startTime.addingTimeInterval(Double(totalFrames) * frameInterval + 1.0)
            if resetDate > currentDate {
                // Animasyon durumu sıfırla
                DispatchQueue.global().asyncAfter(deadline: .now() + resetDate.timeIntervalSinceNow) {
                    userDefaults?.set(false, forKey: "isAnimating")
                    userDefaults?.set(1, forKey: "currentFrame")
                    userDefaults?.removeObject(forKey: "animationStartTime")
                    userDefaults?.synchronize()
                    WidgetCenter.shared.reloadAllTimelines()
                }
                
                let resetEntry = AppEntry(date: resetDate, frameIndex: 1, isAnimating: false)
                entries.append(resetEntry)
            }
            
            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        } else {
            // Normal durum - sadece mevcut frame'i göster
            let entry = AppEntry(date: currentDate, frameIndex: currentFrame, isAnimating: false)
            let timeline = Timeline(entries: [entry], policy: .never)
            completion(timeline)
        }
    }
}

struct AppEntry: TimelineEntry {
    let date: Date
    let frameIndex: Int
    let isAnimating: Bool
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
    static let description = IntentDescription("Animate the frame sequence with 0.5s intervals")
    
    func perform() async throws -> some IntentResult {
        widgetLogger.info("🎬 FrameAnimationIntent başlatıldı - Timeline tabanlı animasyon")
        
        let userDefaults = UserDefaults(suiteName: "group.Iworf.aniWidgets")
        
        // Animasyon başlangıç zamanını kaydet
        userDefaults?.set(Date(), forKey: "animationStartTime")
        userDefaults?.set(true, forKey: "isAnimating")
        userDefaults?.set(1, forKey: "currentFrame")
        userDefaults?.synchronize()
        
        widgetLogger.info("🎬 Timeline animasyonu başlatıldı")
        
        // Widget timeline'ını yeniden yükle
        WidgetCenter.shared.reloadAllTimelines()
        
        return .result()
    }
}

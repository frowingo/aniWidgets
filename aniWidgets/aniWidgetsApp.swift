import SwiftUI
import WidgetKit
import os.log

private let appLogger = Logger(subsystem: "com.aniwidgets.logging", category: "App")

private enum Constants {
    static let appGroupID = "group.Iworf.aniWidgets"
    static let widgetKind = "CounterWidget"
    static let counterKey = "widgetCounter"
}

@main
struct aniWidgetsApp: App {
    let defaults = UserDefaults(suiteName: Constants.appGroupID)
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    initializeCounter()
                }
        }
    }
    
    
    private func initializeCounter() {
        appLogger.info("🚀 App başlatıldı - Counter sıfırlanıyor")
        defaults?.set(0, forKey: Constants.counterKey)
        defaults?.synchronize()
        WidgetCenter.shared.reloadTimelines(ofKind: Constants.widgetKind)
        appLogger.info("✅ Counter sıfırlandı ve widget yenilendi")
    }
}

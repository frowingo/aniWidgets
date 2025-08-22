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
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // App başladığında widget'ı sıfırla
                    let userDefaults = UserDefaults(suiteName: Constants.appGroupID)
                    userDefaults?.set(1, forKey: "currentFrame")
                    userDefaults?.synchronize()
                    WidgetCenter.shared.reloadAllTimelines()
                    appLogger.info("🚀 App başlatıldı - Widget sıfırlandı")
                }
        }
    }
}

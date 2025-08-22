import SwiftUI
import WidgetKit
import os.log

private let appLogger = Logger(subsystem: "com.aniwidgets.logging", category: "App")

@main
struct aniWidgetsApp: App {
    
    init() {
        // App başladığında temel kurulumu yap
        setupAppGroup()
        appLogger.info("🚀 aniWidgets App initialized")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Ana ekran göründüğünde widget'ları güncelle
                    WidgetCenter.shared.reloadAllTimelines()
                    appLogger.info("🔄 Widgets reloaded on app appear")
                    
                    // Eski instance'ları temizle
                    WidgetInstanceManager.shared.cleanupOldInstances()
                }
        }
    }
    
    private func setupAppGroup() {
        // App Group dizin yapısını oluştur
        let _ = AppGroupManager.shared
        appLogger.info("📁 App Group setup completed")
    }
}

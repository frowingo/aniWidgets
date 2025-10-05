import SwiftUI
import WidgetKit
import os.log
import SharedKit

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
                }
        }
    }
    
    private func setupAppGroup() {
        // App Group dizin yapısını oluştur
        let _ = AppGroupStore.shared
        
        // Design Manager'ı başlat (otomatik sync tetikler)
        let _ = DesignManager.shared
        
        appLogger.info("📁 App Group setup completed with frame sync")
    }
}

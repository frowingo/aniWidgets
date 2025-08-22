import SwiftUI
import WidgetKit

struct SettingsView: View {
    @ObservedObject private var designManager = DesignManager.shared
    private let instanceManager = WidgetInstanceManager.shared
    private let appGroupManager = AppGroupManager.shared
    
    @State private var showingClearCache = false
    @State private var cacheSize: String = "Calculating..."
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // App Info
                appInfoSection
                
                // Widget Stats
                widgetStatsSection
                
                // Storage Management
                storageSection
                
                // Debug Actions
                debugSection
                
                // About
                aboutSection
            }
            .padding()
        }
        .onAppear {
            calculateCacheSize()
        }
    }
    
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("App Information")
            
            InfoRow(title: "Version", value: "1.0.0")
            InfoRow(title: "Build", value: "1")
            InfoRow(title: "App Group", value: appGroupManager.appGroupId)
            
            Divider()
        }
    }
    
    private var widgetStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Widget Statistics")
            
            InfoRow(
                title: "Featured Designs",
                value: "\(designManager.featuredConfig.designs.count)/4"
            )
            
            InfoRow(
                title: "Downloaded Designs",
                value: "\(getDownloadedDesignsCount())"
            )
            
            InfoRow(
                title: "Active Widget Instances",
                value: "\(instanceManager.getActiveInstancesCount())"
            )
            
            Divider()
        }
    }
    
    private var storageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Storage Management")
            
            InfoRow(title: "Cache Size", value: cacheSize)
            
            Button(action: {
                showingClearCache = true
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Clear Downloaded Designs")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .foregroundColor(.red)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .alert("Clear Cache", isPresented: $showingClearCache) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    clearCache()
                }
            } message: {
                Text("This will remove all downloaded design files. Featured designs will need to be re-downloaded.")
            }
            
            Divider()
        }
    }
    
    private var debugSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Debug Actions")
            
            Button(action: {
                WidgetCenter.shared.reloadAllTimelines()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Reload All Widgets")
                    Spacer()
                }
                .foregroundColor(.blue)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            
            Button(action: {
                instanceManager.cleanupOldInstances()
            }) {
                HStack {
                    Image(systemName: "text.badge.minus")
                    Text("Cleanup Old Widget States")
                    Spacer()
                }
                .foregroundColor(.orange)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            
            Button(action: {
                resetAllSettings()
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset All Settings")
                    Spacer()
                }
                .foregroundColor(.red)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            
            Divider()
        }
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("About")
            
            Text("Animated Widgets allows you to add beautiful animated widgets to your home screen. Choose up to 4 featured designs that will appear in your widget gallery.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                .font(.subheadline)
                .foregroundColor(.blue)
            
            Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                .font(.subheadline)
                .foregroundColor(.blue)
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
    }
    
    private func calculateCacheSize() {
        DispatchQueue.global(qos: .background).async {
            let size = appGroupManager.getDirectorySize(appGroupManager.designsDirectory)
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            
            DispatchQueue.main.async {
                cacheSize = formatter.string(fromByteCount: size)
            }
        }
    }
    
    private func getDownloadedDesignsCount() -> Int {
        return designManager.availableDesigns.filter { design in
            designManager.isDesignDownloaded(design.id)
        }.count
    }
    
    private func clearCache() {
        do {
            // Clear all downloaded designs
            let designsContents = try FileManager.default.contentsOfDirectory(
                at: appGroupManager.designsDirectory,
                includingPropertiesForKeys: nil
            )
            
            for designFolder in designsContents {
                try FileManager.default.removeItem(at: designFolder)
            }
            
            // Reset featured config
            designManager.featuredConfig = FeaturedConfig()
            designManager.saveFeaturedConfig()
            
            calculateCacheSize()
            
        } catch {
            print("Error clearing cache: \(error)")
        }
    }
    
    private func resetAllSettings() {
        clearCache()
        instanceManager.cleanupOldInstances(olderThan: 0) // Remove all instances
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    SettingsView()
}

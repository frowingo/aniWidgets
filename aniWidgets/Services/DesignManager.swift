import Foundation
import SwiftUI
import WidgetKit
import SharedKit
import os.log

/// Manages animation designs for the app and widget
class DesignManager: ObservableObject {
    static let shared = DesignManager()
    
    private let appGroupManager = AppGroupManager.shared
    private let logger = Logger(subsystem: "com.aniwidgets.logging", category: "DesignManager")
    
    @Published var availableDesigns: [AnimationDesign] = []
    @Published var featuredConfig: FeaturedConfig = FeaturedConfig()
    @Published var featuredDesigns: [AnimationDesign] = []
    @Published var testDesigns: [AnimationDesign] = []
    @Published var isLoading = false
    
    private init() {
        loadLocalDesigns()
        loadFeaturedConfig()
    }
    
    // MARK: - Design Loading
    
    func loadLocalDesigns() {
        // frowi - designlar'ı yüklemenin başladığını belirtti
        isLoading = true
        
        // frowi - tüm desingleri bu arrayde tutucak
        var designs: [AnimationDesign] = []
        // frowi - test desingleri bu arrayde tutucak
        var allTestDesigns: [AnimationDesign] = []
        
        
        // frowi - statik test desingleri bundle'dan okuyup kaydediyor
        if let testDesignsPath = Bundle.main.path(forResource: "TestDesigns", ofType: nil),
           let testDesigns = loadTestDesigns(from: testDesignsPath) {
            designs.append(contentsOf: testDesigns)
            allTestDesigns.append(contentsOf: testDesigns)
        }
        
        if allTestDesigns.isEmpty {
        }
        
        // Load designs from App Group directory
        // frowi - appGroup'a kaydedilmiş olan designleri yüklüyor
        let appGroupDesigns = loadAppGroupDesigns()
        designs.append(contentsOf: appGroupDesigns)
        
        DispatchQueue.main.async {
            self.availableDesigns = designs
            self.testDesigns = allTestDesigns
            self.isLoading = false // frowi - design yükleme bitti
            self.updateFeaturedDesigns()
        }
    }
    
    private func loadTestDesigns(from path: String) -> [AnimationDesign]? {
        let fileManager = FileManager.default
        var designs: [AnimationDesign] = []
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: path)
            
            for item in contents {
                let itemPath = "\(path)/\(item)"
                var isDirectory: ObjCBool = false
                
                if fileManager.fileExists(atPath: itemPath, isDirectory: &isDirectory) && isDirectory.boolValue {
                    if let design = loadDesignFromDirectory(itemPath, designId: item) {
                        designs.append(design)
                    }
                }
            }
        } catch {
            return nil
        }
        
        return designs
    }
    
    private func loadAppGroupDesigns() -> [AnimationDesign] {
        var designs: [AnimationDesign] = []
        
        let designsDirectory = appGroupManager.designsDirectory
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: designsDirectory, includingPropertiesForKeys: nil)
            
            for designFolder in contents {
                if let design = loadDesignFromAppGroup(designFolder) {
                    designs.append(design)
                }
            }
        } catch {
        }
        
        return designs
    }
    
    private func detectDesignId(in path: String) -> String? {
        // Scan directory to infer designId from files like <prefix>_frame_01.png
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: path)
            for name in contents {
                // quick filter to avoid regex overhead
                if name.contains("_frame_") && name.hasSuffix(".png") {
                    // split on "_frame_"
                    let parts = name.components(separatedBy: "_frame_")
                    if let prefix = parts.first, !prefix.isEmpty {
                        return prefix
                    }
                }
            }
        } catch {
        }
        return nil
    }
    
    private func loadDesignFromDirectory(_ path: String, designId: String) -> AnimationDesign? {
        let manifestPath = "\(path)/\(designId)_manifest.json"
        
        // If there's a manifest, prefer it
        if FileManager.default.fileExists(atPath: manifestPath) {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: manifestPath))
                let manifest = try JSONDecoder().decode(DesignManifest.self, from: data)
                return AnimationDesign(
                    id: designId, // keep folder name as id when manifest exists
                    name: manifest.name ?? designId.capitalized,
                    podiumName: manifest.podiumName ?? designId.capitalized,
                    frameCount: manifest.frameCount,
                    frameRate: manifest.frameRate
                )
            } catch {
            }
        }
        
        // No (or failed) manifest: infer the real prefix from files if needed
        let inferredId = detectDesignId(in: path) ?? designId
        let frameCount = countFrames(in: path, designId: inferredId)
        
        guard frameCount > 0 else { return nil }
        
        return AnimationDesign(
            id: inferredId,
            name: inferredId.capitalized,
            podiumName: inferredId.capitalized,
            frameCount: frameCount
        )
    }
    
    private func loadDesignFromAppGroup(_ folderURL: URL) -> AnimationDesign? {
        let designId = folderURL.lastPathComponent
        let manifestURL = folderURL.appendingPathComponent("\(designId)_manifest.json")
        
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            return nil
        }
        
        do {
            let design = try appGroupManager.loadData(AnimationDesign.self, from: manifestURL)
            return design
        } catch {
            return nil
        }
    }
    
    private func countFrames(in path: String, designId: String) -> Int {
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: path)
            // primary: exact prefix
            var count = contents.filter { $0.hasPrefix("\(designId)_frame_") && $0.hasSuffix(".png") }.count
            if count == 0 {
                // fallback: lowercase prefix
                let lower = designId.lowercased()
                count = contents.filter { $0.hasPrefix("\(lower)_frame_") && $0.hasSuffix(".png") }.count
            }
            if count == 0 {
                // fallback: uppercase prefix
                let upper = designId.uppercased()
                count = contents.filter { $0.hasPrefix("\(upper)_frame_") && $0.hasSuffix(".png") }.count
            }
            if count == 0 {
                // last resort: any *_frame_XX.png regardless of prefix
                count = contents.filter { $0.contains("_frame_") && $0.hasSuffix(".png") }.count
            }
            return count
        } catch {
            return 0
        }
    }
    
    // MARK: - Featured Designs Management
    
    func loadFeaturedConfig() {
        do {
            self.featuredConfig = try appGroupManager.loadData(FeaturedConfig.self, from: appGroupManager.featuredConfigPath)
            
            // Update featuredDesigns array
            updateFeaturedDesigns()
        } catch {
            self.featuredConfig = FeaturedConfig()
            updateFeaturedDesigns()
        }
    }
    
    private func updateFeaturedDesigns() {
        self.featuredDesigns = availableDesigns.filter { design in
            featuredConfig.designs.contains(design.id)
        }
    }
    
    func saveFeaturedConfig() {
        self.updateFeaturedDesigns()
        do {
            try appGroupManager.saveData(self.featuredConfig, to: appGroupManager.featuredConfigPath)

            // 👇 Frame'leri App Group'a kopyala
            if let testDesignsPath = Bundle.main.path(forResource: "TestDesigns", ofType: nil) {
                
                for id in self.featuredConfig.designs {
                    if let design = self.getDesign(by: id) {
                        let designBundlePath = "\(testDesignsPath)/\(design.id)"
                        
                        do {
                            try self.appGroupManager.copyFramesToAppGroup(for: design, from: designBundlePath)
                            
                            // Verify frames were copied
                            let isVerified = self.appGroupManager.verifyDesignFrames(for: design.id)
                        } catch {
                        }
                    } else {
                    }
                }
            } else {
            }
            
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
        }
    }
    
    func addToFeatured(_ designId: String) {
        guard !self.featuredConfig.designs.contains(designId) else { return }
        guard self.featuredConfig.designs.count < self.featuredConfig.maxCount else { return }
        
        self.featuredConfig.designs.append(designId)
        
        // Copy frames to bundle cache for real-time widget updates
        do {
            try appGroupManager.copyFramesToBundle(for: designId)
        } catch {
        }
        
        saveFeaturedConfig()
    }
    
    func removeFromFeatured(_ designId: String) {
        self.featuredConfig.designs.removeAll { $0 == designId }
        
        // Remove frames from bundle cache since no longer featured
        do {
            try appGroupManager.removeFramesFromBundle(for: designId)
        } catch {
        }
        
        saveFeaturedConfig()
    }
    
    func moveFeaturedDesign(from source: IndexSet, to destination: Int) {
        self.featuredConfig.designs.move(fromOffsets: source, toOffset: destination)
        saveFeaturedConfig()
    }
    
    // MARK: - Design Operations
    
    func getDesign(by id: String) -> AnimationDesign? {
        return availableDesigns.first { $0.id == id }
    }
    
    func getFrameImage(for designId: String, frameIndex: Int) -> UIImage? {
        // First try App Group (primary source)
        if let appGroupImage = loadFrameFromAppGroup(designId: designId, frameIndex: frameIndex) {
            return appGroupImage
        }
        
        // Fallback: Try to load from bundle and copy to App Group
        if let bundleImage = loadFrameFromBundle(designId: designId, frameIndex: frameIndex) {
            // Copy this design to App Group for future use
            Task {
                if let design = getDesign(by: designId),
                   let testDesignsPath = Bundle.main.path(forResource: "TestDesigns", ofType: nil) {
                    let designBundlePath = "\(testDesignsPath)/\(designId)"
                    try? appGroupManager.copyFramesToAppGroup(for: design, from: designBundlePath)
                }
            }
            return bundleImage
        }
        
        return nil
    }
    
    private func loadFrameFromBundle(designId: String, frameIndex: Int) -> UIImage? {
        let frameBase = String(format: "\(designId)_frame_%02d", frameIndex + 1)
        // Look for a PNG inside TestDesigns/<designId>
        if let path = Bundle.main.path(
            forResource: frameBase,
            ofType: "png",
            inDirectory: "TestDesigns/\(designId)"
        ) {
            return UIImage(contentsOfFile: path)
        }
        // Fallback: try without explicit inDirectory (in case of flat resources)
        if let path = Bundle.main.path(forResource: "\(designId)/\(frameBase)", ofType: "png") {
            return UIImage(contentsOfFile: path)
        }
        return nil
    }
    
    private func loadFrameFromAppGroup(designId: String, frameIndex: Int) -> UIImage? {
        let frameName = String(format: "\(designId)_frame_%02d.png", frameIndex + 1)
        let frameURL = appGroupManager.designFramesDirectory(for: designId).appendingPathComponent(frameName)
        
        guard FileManager.default.fileExists(atPath: frameURL.path) else {
            return nil
        }
        
        return UIImage(contentsOfFile: frameURL.path)
    }
    
    func refreshDesigns() {
        loadLocalDesigns()
    }
    
    func isDesignDownloaded(_ designId: String) -> Bool {
        // Check if design exists in App Group directory
        let designDir = appGroupManager.designDirectory(for: designId)
        return FileManager.default.fileExists(atPath: designDir.path)
    }
    
    // Debug function to check App Group state
    func debugAppGroupState() {
        
        do {
            let designContents = try FileManager.default.contentsOfDirectory(at: appGroupManager.designsDirectory, includingPropertiesForKeys: nil)
            for designDir in designContents {
                let framesDir = appGroupManager.designFramesDirectory(for: designDir.lastPathComponent)
                if FileManager.default.fileExists(atPath: framesDir.path) {
                    let frames = try? FileManager.default.contentsOfDirectory(atPath: framesDir.path)
                } else {
                }
            }
        } catch {
        }
    }
}

// MARK: - Supporting Models

private struct DesignManifest: Codable {
    let name: String?
    let podiumName: String?
    let frameCount: Int
    let frameRate: Double
    
    enum CodingKeys: String, CodingKey {
        case name
        case podiumName
        case frameCount = "frame_count"
        case frameRate = "frame_rate"
    }
}

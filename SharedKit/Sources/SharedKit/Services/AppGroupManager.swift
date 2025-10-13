import Foundation
import os.log

public class AppGroupManager {
    public static let shared = AppGroupManager()
    private let logger = Logger(subsystem: "com.aniwidgets.logging", category: "AppGroup")
    
    public let appGroupId = "group.Iworf.aniWidgets"
    private let fileManager = FileManager.default
    
    // MARK: - Directory Structure
    public lazy var appGroupDirectory: URL = {
        guard let url = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            fatalError("App Group directory not found: \(appGroupId)")
        }
        return url
    }()
    
    public lazy var designsDirectory: URL = {
        let url = appGroupDirectory.appendingPathComponent("Designs")
        createDirectoryIfNeeded(url)
        return url
    }()
    
    public lazy var stateDirectory: URL = {
        let url = appGroupDirectory.appendingPathComponent("State")
        createDirectoryIfNeeded(url)
        return url
    }()
    
    public lazy var instancesDirectory: URL = {
        let url = stateDirectory.appendingPathComponent("instances")
        createDirectoryIfNeeded(url)
        return url
    }()
    
    public lazy var configDirectory: URL = {
        let url = appGroupDirectory.appendingPathComponent("Config")
        createDirectoryIfNeeded(url)
        return url
    }()
    
    private init() {
        logger.info("🗂️ AppGroupManager initialized - App Group: \(self.appGroupId)")
        setupDirectoryStructure()
    }
    
    // MARK: - Directory Management
    private func setupDirectoryStructure() {
        [designsDirectory, stateDirectory, instancesDirectory, configDirectory].forEach { url in
            createDirectoryIfNeeded(url)
        }
        logger.info("🗂️ Directory structure created")
    }
    
    private func createDirectoryIfNeeded(_ url: URL) {
        guard !fileManager.fileExists(atPath: url.path) else { return }
        
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        } catch {
            logger.error("❌ Failed to create directory: \(url.path) - \(error.localizedDescription)")
        }
    }
    
    // MARK: - Generic Data Management
    
    public func saveData<T: Codable>(_ data: T, to path: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let jsonData = try encoder.encode(data)
        try jsonData.write(to: path)
        
        logger.info("💾 Saved data to \(path.lastPathComponent)")
    }
    
    public func loadData<T: Codable>(_ type: T.Type, from path: URL) throws -> T {
        let jsonData = try Data(contentsOf: path)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let data = try decoder.decode(type, from: jsonData)
        logger.info("📂 Loaded data from \(path.lastPathComponent)")
        
        return data
    }
    
    // MARK: - Design Paths
    public func designDirectory(for designId: String) -> URL {
        return designsDirectory.appendingPathComponent(designId)
    }
    
    public func designManifestPath(for designId: String) -> URL {
        return designDirectory(for: designId).appendingPathComponent("\(designId)_manifest.json")
    }
    
    public func designFramesDirectory(for designId: String) -> URL {
        let url = designDirectory(for: designId).appendingPathComponent("frames")
        createDirectoryIfNeeded(url)
        return url
    }
    
    public var featuredConfigPath: URL {
        return stateDirectory.appendingPathComponent("featured_config.json")
    }
    
    public func frameImagePath(for designId: String, frameIndex: Int) -> URL {
        let frameFileName = "\(designId)_frame_\(String(format: "%02d", frameIndex)).png"
        return designFramesDirectory(for: designId).appendingPathComponent(frameFileName)
    }
    
    // MARK: - Instance State Paths
    public func instanceStatePath(for instanceId: String) -> URL {
        return instancesDirectory.appendingPathComponent("\(instanceId).json")
    }
    
    // MARK: - File Operations
    public func deleteDesign(_ designId: String) throws {
        let designDir = designDirectory(for: designId)
        if fileManager.fileExists(atPath: designDir.path) {
            try fileManager.removeItem(at: designDir)
            logger.info("🗑️ Deleted design: \(designId)")
        }
    }
    
    public func designExists(_ designId: String) -> Bool {
        let manifestPath = designManifestPath(for: designId)
        return fileManager.fileExists(atPath: manifestPath.path)
    }
    
    // MARK: - Cleanup Operations
    public func cleanupUnusedDesigns(keepingIds: Set<String>) throws {
        let designsContents = try fileManager.contentsOfDirectory(at: designsDirectory, includingPropertiesForKeys: nil)
        
        for designFolder in designsContents {
            let designId = designFolder.lastPathComponent
            if !keepingIds.contains(designId) {
                try fileManager.removeItem(at: designFolder)
                logger.info("🧹 Cleaned up unused design: \(designId)")
            }
        }
    }
    
    public func getDirectorySize(_ url: URL) -> Int64 {
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        
        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(resourceValues.fileSize ?? 0)
            } catch {
                continue
            }
        }
        return totalSize
    }
    
    
    // MARK: - Frame Management
    public func copyFramesToAppGroup(for design: AnimationDesign, from bundlePath: String) throws {
        let designDir = designDirectory(for: design.id)
        let framesDir = designFramesDirectory(for: design.id)
        
        logger.info("🔄 Copying frames for design: \(design.id)")
        
        // Copy all frame files
        for frameIndex in 1...design.frameCount {
            let frameName = "\(design.id)_frame_\(String(format: "%02d", frameIndex)).png"
            let sourcePath = "\(bundlePath)/\(frameName)"
            let destinationURL = framesDir.appendingPathComponent(frameName)
            
            // Skip if already exists
            if fileManager.fileExists(atPath: destinationURL.path) {
                continue
            }
            
            // Copy frame file
            if fileManager.fileExists(atPath: sourcePath) {
                try fileManager.copyItem(atPath: sourcePath, toPath: destinationURL.path)
                logger.info("✅ Copied frame: \(frameName)")
            } else {
                logger.warning("⚠️ Frame not found: \(sourcePath)")
            }
        }
        
        // Copy manifest file
        let manifestSource = "\(bundlePath)/\(design.id)_manifest.json"
        let manifestDest = designDir.appendingPathComponent("\(design.id)_manifest.json")
        
        if fileManager.fileExists(atPath: manifestSource) && !fileManager.fileExists(atPath: manifestDest.path) {
            try fileManager.copyItem(atPath: manifestSource, toPath: manifestDest.path)
            logger.info("✅ Copied manifest for: \(design.id)")
        }
    }

    public func verifyDesignFrames(for designId: String) -> Bool {
        let framesDir = designFramesDirectory(for: designId)
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: framesDir.path)
            let frameCount = contents.filter { $0.hasPrefix("\(designId)_frame_") && $0.hasSuffix(".png") }.count
            logger.info("📊 Design \(designId) has \(frameCount) frames in App Group")
            return frameCount > 0
        } catch {
            logger.error("❌ Failed to verify frames for \(designId): \(error)")
            return false
        }
    }

    public func syncAllDesignsToAppGroup(designs: [AnimationDesign]) async throws {
        logger.info("🔄 Starting bulk sync of \(designs.count) designs to App Group")
        
        guard let testDesignsPath = Bundle.main.path(forResource: "TestDesigns", ofType: nil) else {
            throw AppGroupError.testDesignsNotFound
        }
        
        for design in designs {
            let designBundlePath = "\(testDesignsPath)/\(design.id)"
            
            if fileManager.fileExists(atPath: designBundlePath) {
                do {
                    try copyFramesToAppGroup(for: design, from: designBundlePath)
                    logger.info("✅ Synced design: \(design.id)")
                } catch {
                    logger.error("❌ Failed to sync design \(design.id): \(error)")
                }
            }
        }
        
        logger.info("🎉 Bulk sync completed")
    }

    enum AppGroupError: Error {
        case testDesignsNotFound
        case frameCopyFailed(String)
    }
}

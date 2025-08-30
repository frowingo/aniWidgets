import Foundation
import os.log

class AppGroupManager {
    static let shared = AppGroupManager()
    private let logger = Logger(subsystem: "com.aniwidgets.logging", category: "AppGroup")
    
    // App Group Configuration
    let appGroupId = "group.Iworf.aniWidgets"
    private let fileManager = FileManager.default
    
    // MARK: - Directory Structure
    lazy var appGroupDirectory: URL = {
        guard let url = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            fatalError("App Group directory not found: \(appGroupId)")
        }
        return url
    }()
    
    lazy var designsDirectory: URL = {
        let url = appGroupDirectory.appendingPathComponent("Designs")
        createDirectoryIfNeeded(url)
        return url
    }()
    
    lazy var stateDirectory: URL = {
        let url = appGroupDirectory.appendingPathComponent("State")
        createDirectoryIfNeeded(url)
        return url
    }()
    
    lazy var instancesDirectory: URL = {
        let url = stateDirectory.appendingPathComponent("instances")
        createDirectoryIfNeeded(url)
        return url
    }()
    
    lazy var configDirectory: URL = {
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
    
    func saveData<T: Codable>(_ data: T, to path: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let jsonData = try encoder.encode(data)
        try jsonData.write(to: path)
        
        logger.info("💾 Saved data to \(path.lastPathComponent)")
    }
    
    func loadData<T: Codable>(_ type: T.Type, from path: URL) throws -> T {
        let jsonData = try Data(contentsOf: path)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let data = try decoder.decode(type, from: jsonData)
        logger.info("📂 Loaded data from \(path.lastPathComponent)")
        
        return data
    }
    
    // MARK: - Design Paths
    func designDirectory(for designId: String) -> URL {
        return designsDirectory.appendingPathComponent(designId)
    }
    
    func designManifestPath(for designId: String) -> URL {
        return designDirectory(for: designId).appendingPathComponent("\(designId)_manifest.json")
    }
    
    func designFramesDirectory(for designId: String) -> URL {
        let url = designDirectory(for: designId).appendingPathComponent("frames")
        createDirectoryIfNeeded(url)
        return url
    }
    
    var featuredConfigPath: URL {
        return stateDirectory.appendingPathComponent("featured_config.json")
    }
    
    func frameImagePath(for designId: String, frameIndex: Int) -> URL {
        let frameFileName = "\(designId)_frame_\(String(format: "%02d", frameIndex)).png"
        return designFramesDirectory(for: designId).appendingPathComponent(frameFileName)
    }
    
    // MARK: - Instance State Paths
    func instanceStatePath(for instanceId: String) -> URL {
        return instancesDirectory.appendingPathComponent("\(instanceId).json")
    }
    
    // MARK: - File Operations
    func deleteDesign(_ designId: String) throws {
        let designDir = designDirectory(for: designId)
        if fileManager.fileExists(atPath: designDir.path) {
            try fileManager.removeItem(at: designDir)
            logger.info("🗑️ Deleted design: \(designId)")
        }
    }
    
    func designExists(_ designId: String) -> Bool {
        let manifestPath = designManifestPath(for: designId)
        return fileManager.fileExists(atPath: manifestPath.path)
    }
    
    // MARK: - Cleanup Operations
    func cleanupUnusedDesigns(keepingIds: Set<String>) throws {
        let designsContents = try fileManager.contentsOfDirectory(at: designsDirectory, includingPropertiesForKeys: nil)
        
        for designFolder in designsContents {
            let designId = designFolder.lastPathComponent
            if !keepingIds.contains(designId) {
                try fileManager.removeItem(at: designFolder)
                logger.info("🧹 Cleaned up unused design: \(designId)")
            }
        }
    }
    
    func getDirectorySize(_ url: URL) -> Int64 {
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
}

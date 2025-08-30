import Foundation
import SharedKit

// MARK: - Widget Bundle Scanner

struct WidgetBundleScanner {
    private let logger = SharedLogger.shared
    
    func scanForLocalTestDesigns() -> [AnimationDesign] {
        var designs: [AnimationDesign] = []
        
        guard let bundle = Bundle.main.path(forResource: "TestDesigns", ofType: nil) else {
            logger.info("TestDesigns folder not found in widget bundle")
            return designs
        }
        
        let testDesignsURL = URL(fileURLWithPath: bundle)
        logger.info("Found TestDesigns folder at: \(testDesignsURL.path)")
        
        do {
            let designFolders = try FileManager.default.contentsOfDirectory(at: testDesignsURL, includingPropertiesForKeys: nil)
            
            for designFolder in designFolders where designFolder.hasDirectoryPath {
                if let design = loadDesignFromFolder(designFolder) {
                    designs.append(design)
                    logger.info("Loaded test design: \(design.name)")
                }
            }
        } catch {
            logger.error("Failed to scan TestDesigns folder: \(error.localizedDescription)")
        }
        
        return designs
    }
    
    private func loadDesignFromFolder(_ folderURL: URL) -> AnimationDesign? {
        let designId = folderURL.lastPathComponent
        let manifestURL = folderURL.appendingPathComponent("\(designId)_manifest.json")
        
        do {
            let data = try Data(contentsOf: manifestURL)
            let decoder = JSONDecoder()
            
            // Simple manifest structure
            struct Manifest: Codable {
                let id: String
                let name: String
                let podiumName: String
                let category: String
                let frameCount: Int
                let frameDuration: Double?
                let description: String?
                let isLocalTest: Bool?
                let tags: [String]?
            }
            
            let manifest = try decoder.decode(Manifest.self, from: data)
            
            return AnimationDesign(
                id: manifest.id,
                name: manifest.name,
                podiumName: manifest.podiumName,
                frameCount: manifest.frameCount,
                frameRate: 1.0 / (manifest.frameDuration ?? 0.1)
            )
            
        } catch {
            logger.error("Failed to load manifest from \(folderURL.lastPathComponent): \(error.localizedDescription)")
            return nil
        }
    }
    
    func getFrameImage(for designId: String, frameIndex: Int) -> UIImage? {
        guard let bundle = Bundle.main.path(forResource: "TestDesigns", ofType: nil) else {
            return nil
        }
        
        let frameName = String(format: "\(designId)_frame_%02d", frameIndex)
        let imagePath = "\(bundle)/\(designId)/\(frameName).png"
        
        return UIImage(contentsOfFile: imagePath)
    }
}

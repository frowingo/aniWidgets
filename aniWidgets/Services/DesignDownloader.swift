import Foundation
import UIKit
import os.log

class DesignDownloader {
    private let logger = Logger(subsystem: "com.aniwidgets.logging", category: "DesignDownloader")
    private let appGroupManager = AppGroupManager.shared
    private let session = URLSession.shared
    
    func downloadDesign(_ design: WidgetDesign, progressHandler: @escaping (Double) -> Void) async throws {
        logger.info("📥 Starting download for design: \(design.id)")
        
        // Create design directory
        let designDir = appGroupManager.designDirectory(for: design.id)
        let framesDir = appGroupManager.designFramesDirectory(for: design.id)
        
        // For now, we'll simulate the download by copying from existing assets
        // In real implementation, this would download from the actual URLs
        await simulateDownloadFromAssets(design: design, progressHandler: progressHandler)
        
        // Create manifest
        let manifest = DesignManifest(
            designId: design.id,
            name: design.name,
            frameCount: design.frameCount,
            frameInterval: design.frameInterval,
            downloadedAt: Date(),
            frameUrls: (1...design.frameCount).map { "frame_\(String(format: "%02d", $0)).png" }
        )
        
        try appGroupManager.saveData(manifest, to: appGroupManager.designManifestPath(for: design.id))
        logger.info("✅ Design download completed: \(design.id)")
    }
    
    private func simulateDownloadFromAssets(design: WidgetDesign, progressHandler: @escaping (Double) -> Void) async {
        // Simulate downloading frames from bundle to App Group
        let frameCount = design.frameCount
        
        for i in 1...frameCount {
            let frameName = "frame_\(String(format: "%02d", i))"
            
            // Only test01 has real assets, others are placeholders
            if design.id == "test01" {
                // Load from bundle
                if let bundleImage = await loadImageFromBundle(named: frameName) {
                    // Save to App Group
                    let destinationPath = appGroupManager.frameImagePath(for: design.id, frameIndex: i)
                    
                    do {
                        try bundleImage.write(to: destinationPath)
                    } catch {
                        logger.error("❌ Failed to save frame \(i) for design \(design.id): \(error)")
                    }
                } else {
                    logger.warning("⚠️ Frame \(frameName) not found in bundle")
                }
            } else {
                // For other designs, create placeholder gray images
                if let placeholderImage = await createPlaceholderImage(designName: design.name, frameIndex: i) {
                    let destinationPath = appGroupManager.frameImagePath(for: design.id, frameIndex: i)
                    
                    do {
                        try placeholderImage.write(to: destinationPath)
                    } catch {
                        logger.error("❌ Failed to save placeholder frame \(i) for design \(design.id): \(error)")
                    }
                }
            }
            
            // Update progress
            let progress = Double(i) / Double(frameCount)
            progressHandler(progress)
            
            // Simulate network delay
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
        }
    }
    
    @MainActor
    private func createPlaceholderImage(designName: String, frameIndex: Int) async -> Data? {
        let size = CGSize(width: 300, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            // Gray background
            UIColor.systemGray4.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Design name text
            let text = designName
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .semibold),
                .foregroundColor: UIColor.systemGray2
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2 - 20,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
            
            // Frame number
            let frameText = "Frame \(frameIndex)"
            let frameAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: UIColor.systemGray3
            ]
            
            let frameSize = frameText.size(withAttributes: frameAttributes)
            let frameRect = CGRect(
                x: (size.width - frameSize.width) / 2,
                y: (size.height - frameSize.height) / 2 + 20,
                width: frameSize.width,
                height: frameSize.height
            )
            
            frameText.draw(in: frameRect, withAttributes: frameAttributes)
        }
        
        return image.pngData()
    }
    
    @MainActor
    private func loadImageFromBundle(named imageName: String) async -> Data? {
        guard let image = UIImage(named: imageName),
              let data = image.pngData() else {
            return nil
        }
        return data
    }
    
    // MARK: - Real Network Download (for future use)
    private func downloadFromNetwork(url: URL, progressHandler: @escaping (Double) -> Void) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return data
    }
    
    func downloadDesignFromNetwork(_ design: WidgetDesign, progressHandler: @escaping (Double) -> Void) async throws {
        // This method would be used for real network downloads
        logger.info("🌐 Starting network download for design: \(design.id)")
        
        let frameCount = design.frameCount
        var completedFrames = 0
        
        for i in 1...frameCount {
            let frameURL = URL(string: "\(design.framesBaseURL)/frame_\(String(format: "%02d", i)).png")!
            
            do {
                let frameData = try await downloadFromNetwork(url: frameURL, progressHandler: { _ in })
                let destinationPath = appGroupManager.frameImagePath(for: design.id, frameIndex: i)
                
                try frameData.write(to: destinationPath)
                completedFrames += 1
                
                let progress = Double(completedFrames) / Double(frameCount)
                progressHandler(progress)
                
            } catch {
                logger.error("❌ Failed to download frame \(i) for design \(design.id): \(error)")
                throw error
            }
        }
        
        // Create manifest after successful download
        let manifest = DesignManifest(
            designId: design.id,
            name: design.name,
            frameCount: frameCount,
            frameInterval: design.frameInterval,
            downloadedAt: Date(),
            frameUrls: (1...frameCount).map { "frame_\(String(format: "%02d", $0)).png" }
        )
        
        try appGroupManager.saveData(manifest, to: appGroupManager.designManifestPath(for: design.id))
        logger.info("✅ Network download completed: \(design.id)")
    }
}

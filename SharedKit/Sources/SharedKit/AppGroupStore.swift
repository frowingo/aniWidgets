import Foundation
import UIKit
import OSLog

// MARK: - AppGroupStore Protocol

public protocol AppGroupStoreProtocol {
    func containerURL() throws -> URL
    func readJSON<T: Codable>(_ type: T.Type, from fileName: String) throws -> T
    func writeJSON<T: Codable>(_ object: T, to fileName: String) throws
    func readData(from fileName: String) throws -> Data
    func writeData(_ data: Data, to fileName: String) throws
    func deleteFile(_ fileName: String) throws
    func fileExists(_ fileName: String) -> Bool
    func saveImage(_ image: UIImage, to fileName: String) throws -> URL
    func loadImage(from fileName: String) throws -> UIImage
}

// MARK: - AppGroupStore Implementation

public class AppGroupStore: AppGroupStoreProtocol {
    
    public static let shared = AppGroupStore()
    private let appGroupIdentifier = "group.Iworf.aniWidgets"
    private let logger = SharedLogger.shared
    
    private init() {}
    
    public func containerURL() throws -> URL {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            logger.error("App Group container not found for identifier: \(appGroupIdentifier)")
            throw SharedKitError.appGroupNotFound
        }
        return url
    }
    
    public func readJSON<T: Codable>(_ type: T.Type, from fileName: String) throws -> T {
        let data = try readData(from: fileName)
        
        do {
            let object = try JSONDecoder().decode(type, from: data)
            logger.info("Successfully read JSON file: \(fileName)")
            return object
        } catch {
            logger.error("Failed to decode JSON from \(fileName): \(error.localizedDescription)")
            throw SharedKitError.invalidData("Failed to decode JSON: \(error.localizedDescription)")
        }
    }
    
    public func writeJSON<T: Codable>(_ object: T, to fileName: String) throws {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(object)
            try writeData(data, to: fileName)
            logger.info("Successfully wrote JSON file: \(fileName)")
        } catch {
            logger.error("Failed to encode JSON to \(fileName): \(error.localizedDescription)")
            throw SharedKitError.writeError("Failed to encode JSON: \(error.localizedDescription)")
        }
    }
    
    public func readData(from fileName: String) throws -> Data {
        let containerURL = try containerURL()
        let fileURL = containerURL.appendingPathComponent(fileName)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            logger.error("File not found: \(fileURL.path)")
            throw SharedKitError.fileNotFound(fileName)
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            logger.debug("Successfully read data from: \(fileName) (\(data.count) bytes)")
            return data
        } catch {
            logger.error("Failed to read data from \(fileName): \(error.localizedDescription)")
            throw SharedKitError.readError("Failed to read file: \(error.localizedDescription)")
        }
    }
    
    public func writeData(_ data: Data, to fileName: String) throws {
        let containerURL = try containerURL()
        let fileURL = containerURL.appendingPathComponent(fileName)
        
        // Ensure directory exists
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        
        do {
            try data.write(to: fileURL)
            logger.info("Successfully wrote data to: \(fileName) (\(data.count) bytes)")
        } catch {
            logger.error("Failed to write data to \(fileName): \(error.localizedDescription)")
            throw SharedKitError.writeError("Failed to write file: \(error.localizedDescription)")
        }
    }
    
    public func deleteFile(_ fileName: String) throws {
        let containerURL = try containerURL()
        let fileURL = containerURL.appendingPathComponent(fileName)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return // File doesn't exist, nothing to delete
        }
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            logger.info("Successfully deleted file: \(fileName)")
        } catch {
            logger.error("Failed to delete file \(fileName): \(error.localizedDescription)")
            throw SharedKitError.writeError("Failed to delete file: \(error.localizedDescription)")
        }
    }
    
    public func fileExists(_ fileName: String) -> Bool {
        guard let containerURL = try? containerURL() else { return false }
        let fileURL = containerURL.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    public func saveImage(_ image: UIImage, to fileName: String) throws -> URL {
        guard let data = image.pngData() else {
            throw SharedKitError.invalidData("Failed to convert image to PNG data")
        }
        
        let imageFileName = "images/\(fileName)"
        try writeData(data, to: imageFileName)
        
        let containerURL = try containerURL()
        return containerURL.appendingPathComponent(imageFileName)
    }
    
    public func loadImage(from fileName: String) throws -> UIImage {
        let imageFileName = "images/\(fileName)"
        let data = try readData(from: imageFileName)
        
        guard let image = UIImage(data: data) else {
            throw SharedKitError.invalidData("Failed to create image from data")
        }
        
        return image
    }
}

// MARK: - UserDefaults Extension for App Group

public extension UserDefaults {
    static let appGroup = UserDefaults(suiteName: "group.com.frowing.aniWidgets") ?? .standard
    
    // Widget preferences
    var widgetRefreshInterval: TimeInterval {
        get { UserDefaults.appGroup.double(forKey: "widgetRefreshInterval") != 0 ? UserDefaults.appGroup.double(forKey: "widgetRefreshInterval") : 1800 }
        set { UserDefaults.appGroup.set(newValue, forKey: "widgetRefreshInterval") }
    }
    
    var lastWidgetUpdate: Date? {
        get { UserDefaults.appGroup.object(forKey: "lastWidgetUpdate") as? Date }
        set { UserDefaults.appGroup.set(newValue, forKey: "lastWidgetUpdate") }
    }
    
    var currentWidgetDesignId: String? {
        get { UserDefaults.appGroup.string(forKey: "currentWidgetDesignId") }
        set { UserDefaults.appGroup.set(newValue, forKey: "currentWidgetDesignId") }
    }
}

import XCTest
@testable import SharedKit

final class SharedKitTests: XCTestCase {
    
    var mockAppStore: MockAppGroupStore!
    
    override func setUp() {
        super.setUp()
        mockAppStore = MockAppGroupStore()
    }
    
    override func tearDown() {
        mockAppStore = nil
        super.tearDown()
    }
    
    func testWidgetEntryEncodingDecoding() throws {
        let entry = WidgetEntry(
            id: "test-id",
            title: "Test Widget",
            subtitle: "Test Subtitle",
            animationFrames: ["frame_01", "frame_02"],
            frameCount: 2,
            category: "test"
        )
        
        let encoded = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(WidgetEntry.self, from: encoded)
        
        XCTAssertEqual(entry.id, decoded.id)
        XCTAssertEqual(entry.title, decoded.title)
        XCTAssertEqual(entry.frameCount, decoded.frameCount)
    }
    
    func testAnimationDesignEncodingDecoding() throws {
        let design = AnimationDesign(
            id: "animation-test",
            name: "Test Animation",
            category: "test",
            frameCount: 24,
            frameDuration: 0.1,
            tags: ["test", "animation"]
        )
        
        let encoded = try JSONEncoder().encode(design)
        let decoded = try JSONDecoder().decode(AnimationDesign.self, from: encoded)
        
        XCTAssertEqual(design.id, decoded.id)
        XCTAssertEqual(design.name, decoded.name)
        XCTAssertEqual(design.frameCount, decoded.frameCount)
    }
}

// MARK: - Mock Implementation

class MockAppGroupStore: AppGroupStoreProtocol {
    private var storage: [String: Data] = [:]
    
    func containerURL() throws -> URL {
        return URL(fileURLWithPath: "/tmp/mock-app-group")
    }
    
    func readJSON<T: Codable>(_ type: T.Type, from fileName: String) throws -> T {
        guard let data = storage[fileName] else {
            throw SharedKitError.fileNotFound(fileName)
        }
        return try JSONDecoder().decode(type, from: data)
    }
    
    func writeJSON<T: Codable>(_ object: T, to fileName: String) throws {
        let data = try JSONEncoder().encode(object)
        storage[fileName] = data
    }
    
    func readData(from fileName: String) throws -> Data {
        guard let data = storage[fileName] else {
            throw SharedKitError.fileNotFound(fileName)
        }
        return data
    }
    
    func writeData(_ data: Data, to fileName: String) throws {
        storage[fileName] = data
    }
    
    func deleteFile(_ fileName: String) throws {
        storage.removeValue(forKey: fileName)
    }
    
    func fileExists(_ fileName: String) -> Bool {
        return storage[fileName] != nil
    }
    
    func saveImage(_ image: UIImage, to fileName: String) throws -> URL {
        guard let data = image.pngData() else {
            throw SharedKitError.invalidData("Cannot convert image to PNG")
        }
        try writeData(data, to: "images/\(fileName)")
        return try containerURL().appendingPathComponent("images/\(fileName)")
    }
    
    func loadImage(from fileName: String) throws -> UIImage {
        let data = try readData(from: "images/\(fileName)")
        guard let image = UIImage(data: data) else {
            throw SharedKitError.invalidData("Cannot create image from data")
        }
        return image
    }
}

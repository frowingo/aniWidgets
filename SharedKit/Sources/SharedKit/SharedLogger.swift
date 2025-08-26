import Foundation
import OSLog

public class SharedLogger {
    public static let shared = SharedLogger()
    
    private let logger: Logger
    
    private init() {
        self.logger = Logger(subsystem: "com.frowing.aniWidgets", category: "SharedKit")
    }
    
    public func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        logger.debug("[\(fileName):\(line)] \(function) - \(message)")
    }
    
    public func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        logger.info("[\(fileName):\(line)] \(function) - \(message)")
    }
    
    public func notice(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        logger.notice("[\(fileName):\(line)] \(function) - \(message)")
    }
    
    public func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        logger.warning("[\(fileName):\(line)] \(function) - \(message)")
    }
    
    public func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        logger.error("[\(fileName):\(line)] \(function) - \(message)")
    }
    
    public func critical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        logger.critical("[\(fileName):\(line)] \(function) - \(message)")
    }
}

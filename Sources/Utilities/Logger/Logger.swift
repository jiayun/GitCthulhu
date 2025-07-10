import Foundation
import os.log

public struct Logger {
    private let logger: os.Logger

    public init(subsystem: String = "com.gitcthulhu", category: String) {
        logger = os.Logger(subsystem: subsystem, category: category)
    }

    public func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.debug("\(message) [\(URL(fileURLWithPath: file).lastPathComponent):\(line) \(function)]")
    }

    public func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.info("\(message) [\(URL(fileURLWithPath: file).lastPathComponent):\(line) \(function)]")
    }

    public func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.warning("\(message) [\(URL(fileURLWithPath: file).lastPathComponent):\(line) \(function)]")
    }

    public func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.error("\(message) [\(URL(fileURLWithPath: file).lastPathComponent):\(line) \(function)]")
    }

    public func fault(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logger.fault("\(message) [\(URL(fileURLWithPath: file).lastPathComponent):\(line) \(function)]")
    }
}

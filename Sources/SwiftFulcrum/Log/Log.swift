// Log.swift

import Foundation

public enum Log {}

extension Log {
    public enum Level: Sendable {
        case trace, debug, info, notice, warning, error, critical
    }
    
    public protocol Handler: Sendable {
        func log(_ level: Level,
                 _ message: @autoclosure () -> String,
                 metadata: [String: String]?,
                 file: String, function: String, line: UInt)
    }
}

extension Log.Handler {
    func trace(_ message: @autoclosure () -> String,
               metadata: [String: String]? = nil,
               file: String = #fileID, function: String = #function, line: UInt = #line) {
        log(.trace, message(), metadata: metadata, file: file, function: function, line: line)
    }
    
    func debug(_ message: @autoclosure () -> String,
               metadata: [String: String]? = nil,
               file: String = #fileID, function: String = #function, line: UInt = #line) {
        log(.debug, message(), metadata: metadata, file: file, function: function, line: line)
    }
    
    func info(_ message: @autoclosure () -> String,
              metadata: [String: String]? = nil,
              file: String = #fileID, function: String = #function, line: UInt = #line) {
        log(.info, message(), metadata: metadata, file: file, function: function, line: line)
    }
    
    func notice(_ message: @autoclosure () -> String,
                metadata: [String: String]? = nil,
                file: String = #fileID, function: String = #function, line: UInt = #line) {
        log(.notice, message(), metadata: metadata, file: file, function: function, line: line)
    }
    
    func warning(_ message: @autoclosure () -> String,
                 metadata: [String: String]? = nil,
                 file: String = #fileID, function: String = #function, line: UInt = #line) {
        log(.warning, message(), metadata: metadata, file: file, function: function, line: line)
    }
    
    func error(_ message: @autoclosure () -> String,
               metadata: [String: String]? = nil,
               file: String = #fileID, function: String = #function, line: UInt = #line) {
        log(.error, message(), metadata: metadata, file: file, function: function, line: line)
    }
    
    func critical(_ message: @autoclosure () -> String,
                  metadata: [String: String]? = nil,
                  file: String = #fileID, function: String = #function, line: UInt = #line) {
        log(.critical, message(), metadata: metadata, file: file, function: function, line: line)
    }
}


extension Log {
    public struct NoOpHandler: Log.Handler {
        public init() {}
        public func log(_ level: Log.Level, _ message: @autoclosure () -> String, metadata: [String : String]?, file: String, function: String, line: UInt) {}
    }
}

// LogModel.swift

import Foundation

@available(*, deprecated, message: "Use SwiftFulcrum.Logging instead.")
public enum LogModel {}

extension LogModel {
    public enum Level: Sendable {
        case trace, debug, info, notice, warning, error, critical
        
        var name: String {
            switch self {
            case .trace: return "trace"
            case .debug: return "debug"
            case .info: return "info"
            case .notice: return "notice"
            case .warning: return "warning"
            case .error: return "error"
            case .critical: return "critical"
            }
        }
        
        var priority: Int {
            switch self {
            case .trace: return 0
            case .debug: return 1
            case .info: return 2
            case .notice: return 3
            case .warning: return 4
            case .error: return 5
            case .critical: return 6
            }
        }
    }
    
    public protocol Adapter: Sendable {
        func log(_ level: Level,
                 _ message: @autoclosure () -> String,
                 metadata: [String: String]?,
                 file: String, function: String, line: UInt)
    }
}

extension LogModel.Adapter {
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
    
    func logInfo(_ message: @autoclosure () -> String,
                 metadata: [String: String]? = nil,
                 file: String = #fileID, function: String = #function, line: UInt = #line) {
        log(.info, message(), metadata: metadata, file: file, function: function, line: line)
    }
    
    func notice(_ message: @autoclosure () -> String,
                metadata: [String: String]? = nil,
                file: String = #fileID, function: String = #function, line: UInt = #line) {
        log(.notice, message(), metadata: metadata, file: file, function: function, line: line)
    }
    
    func logWarning(_ message: @autoclosure () -> String,
                    metadata: [String: String]? = nil,
                    file: String = #fileID, function: String = #function, line: UInt = #line) {
        log(.warning, message(), metadata: metadata, file: file, function: function, line: line)
    }
    
    func logError(_ message: @autoclosure () -> String,
                  metadata: [String: String]? = nil,
                  file: String = #fileID, function: String = #function, line: UInt = #line) {
        log(.error, message(), metadata: metadata, file: file, function: function, line: line)
    }
    
    func logCritical(_ message: @autoclosure () -> String,
                     metadata: [String: String]? = nil,
                     file: String = #fileID, function: String = #function, line: UInt = #line) {
        log(.critical, message(), metadata: metadata, file: file, function: function, line: line)
    }
}

extension LogModel {
    public struct NoOperationAdapter: LogModel.Adapter {
        public init() {}
        public func log(_ level: LogModel.Level, _ message: @autoclosure () -> String, metadata: [String : String]?, file: String, function: String, line: UInt) {}
    }
}

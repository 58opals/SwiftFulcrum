// Log.swift

import Foundation

public enum Log {}

extension Log {
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

extension Log {
    public struct ConsoleHandler: Log.Handler {
        private let dateProvider: @Sendable () -> Date
        private let minimumLevel: Level?
        
        public init(dateProvider: @escaping @Sendable () -> Date = Date.init, minimumLevel: Level? = nil) {
            self.dateProvider = dateProvider
            self.minimumLevel = minimumLevel
        }
        
        public func log(_ level: Log.Level,
                        _ message: @autoclosure () -> String,
                        metadata: [String : String]?,
                        file: String,
                        function: String,
                        line: UInt) {
            guard shouldLog(level) else { return }
            
            let timestamp = ISO8601DateFormatter().string(from: dateProvider())
            let levelTag = makeLevelTag(level)
            let location = makeLocationTag(file: file, function: function, line: line)
            let metadataDescription = makeMetadataDescription(metadata)
            
            let composed = ["[\(timestamp)]", levelTag, location, message(), metadataDescription]
                .compactMap { $0 }
                .joined(separator: " ")
            
            print(composed)
        }
        
        private func shouldLog(_ level: Level) -> Bool {
            guard let minimumLevel else { return true }
            return level.priority >= minimumLevel.priority
        }
        
        private func makeLevelTag(_ level: Level) -> String { "[\(level.name)]" }
        
        private func makeLocationTag(file: String, function: String, line: UInt) -> String {
            "[\(file):\(line) \(function)]"
        }
        
        private func makeMetadataDescription(_ metadata: [String: String]?) -> String? {
            guard let metadata, !metadata.isEmpty else { return nil }
            let pairs = metadata
                .sorted { $0.key < $1.key }
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: " ")
            return "{\(pairs)}"
        }
    }
}

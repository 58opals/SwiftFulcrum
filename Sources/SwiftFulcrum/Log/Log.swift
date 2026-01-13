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
        
        private let outputSink: OutputSink
        
        private static var dateFormatter: ISO8601DateFormatter {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return formatter
        }
        
        public init(
            dateProvider: @escaping @Sendable () -> Date = Date.init,
            minimumLevel: Level? = nil,
            outputSink: OutputSink = .shared
        ) {
            self.dateProvider = dateProvider
            self.minimumLevel = minimumLevel
            self.outputSink = outputSink
        }
        
        public func log(_ level: Log.Level,
                        _ message: @autoclosure () -> String,
                        metadata: [String : String]?,
                        file: String,
                        function: String,
                        line: UInt) {
            guard allowLogging(for: level) else { return }
            let entry = Entry(
                level: level,
                timestamp: Self.dateFormatter.string(from: dateProvider()),
                message: message(),
                metadata: metadata,
                file: file,
                function: function,
                line: line
            )
            
            let composed = compose(entry)
            let signature = makeSignature(for: entry)
            
            Task { await outputSink.enqueue(rendered: composed, signature: signature) }
        }
        
        private func allowLogging(for level: Level) -> Bool {
            guard let minimumLevel else { return true }
            return level.priority >= minimumLevel.priority
        }
        private func compose(_ entry: Entry) -> String {
            let component = makeComponentTag(from: entry.metadata)
            let scope = makeScopeTag(file: entry.file, function: entry.function, line: entry.line)
            let metadata = makeMetadataDescription(entry.metadata)
            
            return [
                "[\(entry.timestamp)]",
                "[\(entry.level.name)]",
                component,
                entry.message,
                metadata,
                scope
            ]
                .compactMap { $0 }
                .joined(separator: " ")
        }
        
        private func makeComponentTag(from metadata: [String: String]?) -> String? {
            guard let metadata else { return nil }
            
            let prioritizedKeys = ["component", "network", "url", "client_id", "messageIdentifier"]
            let prioritized = prioritizedKeys.compactMap { key -> String? in
                guard let value = metadata[key] else { return nil }
                return "\(key)=\(value)"
            }
            
            guard !prioritized.isEmpty else { return nil }
            return "[\(prioritized.joined(separator: " "))]"
        }
        
        private func makeScopeTag(file: String, function: String, line: UInt) -> String? {
            "(\(file):\(line) \(function))"
        }
        
        private func makeMetadataDescription(_ metadata: [String: String]?) -> String? {
            guard let metadata, !metadata.isEmpty else { return nil }
            
            let excluded = Set(["component", "network", "url", "client_id", "messageIdentifier"])
            let pairs = metadata
                .filter { !excluded.contains($0.key) }
                .sorted { $0.key < $1.key }
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: " ")
            
            guard !pairs.isEmpty else { return nil }
            return "{\(pairs)}"
        }
        
        private func makeSignature(for entry: Entry) -> String {
            [
                entry.level.name,
                entry.message,
                makeMetadataDescription(entry.metadata) ?? "",
                entry.file,
                entry.function,
                String(entry.line)
            ].joined(separator: "|")
        }
    }
    
    public enum Behavior: Sendable {
        case normal
        case quiet
    }
    
    enum Context {
        @TaskLocal static var behavior: Behavior = .normal
    }
    
    public static func perform<T>(
        withBehavior behavior: Behavior,
        operation: @Sendable () async throws -> T
    ) async rethrows -> T {
        try await Context.$behavior.withValue(behavior) {
            try await operation()
        }
    }
}

extension Log.ConsoleHandler {
    struct Entry: Sendable {
        let level: Log.Level
        let timestamp: String
        let message: String
        let metadata: [String: String]?
        let file: String
        let function: String
        let line: UInt
    }
}

extension Log.ConsoleHandler {
    public actor OutputSink: Sendable {
        public static let shared = OutputSink()
        
        private var lastSignature: String?
        private var lastRendered: String?
        private var repeatCount = 0
        private var debounceTask: Task<Void, Never>?
        
        func enqueue(rendered: String, signature: String) async {
            if signature == lastSignature {
                repeatCount += 1
                scheduleFlush()
                return
            }
            
            flushRepeatsIfNeeded()
            
            lastSignature = signature
            lastRendered = rendered
            print(rendered)
        }
        
        private func scheduleFlush() {
            debounceTask?.cancel()
            debounceTask = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(150))
                await self?.flushRepeatsIfNeeded()
            }
        }
        
        private func flushRepeatsIfNeeded() {
            debounceTask?.cancel()
            guard repeatCount > 0 else { return }
            let times = repeatCount
            let repetitionDescriptor = times == 1 ? "1 more time" : "\(times) more times"
            if let lastRendered {
                print("↑ previous line repeated \(repetitionDescriptor): \(lastRendered)")
            } else {
                print("↑ previous line repeated \(repetitionDescriptor)")
            }
            repeatCount = 0
        }
    }
}

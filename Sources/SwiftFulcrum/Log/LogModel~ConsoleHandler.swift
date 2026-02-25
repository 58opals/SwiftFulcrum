// LogModel~ConsoleHandler.swift

import Foundation

extension LogModel {
    public struct ConsoleHandlerModel: LogModel.HandlerModel {
        private let dateProvider: @Sendable () -> Date
        private let minimumLevel: LevelModel?
        
        private let outputSink: OutputSinkModel
        
        private static var dateFormatter: ISO8601DateFormatter {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return formatter
        }
        
        public init(
            dateProvider: @escaping @Sendable () -> Date = Date.init,
            minimumLevel: LevelModel? = nil,
            outputSink: OutputSinkModel = .shared
        ) {
            self.dateProvider = dateProvider
            self.minimumLevel = minimumLevel
            self.outputSink = outputSink
        }
        
        public func log(_ level: LogModel.LevelModel,
                        _ message: @autoclosure () -> String,
                        metadata: [String : String]?,
                        file: String,
                        function: String,
                        line: UInt) {
            guard LogModel.ContextModel.behavior == .normal else { return }
            guard allowLogging(for: level) else { return }
            let entry = EntryModel(
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
        
        private func allowLogging(for level: LevelModel) -> Bool {
            guard let minimumLevel else { return true }
            return level.priority >= minimumLevel.priority
        }
        private func compose(_ entry: EntryModel) -> String {
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
        
        private func makeSignature(for entry: EntryModel) -> String {
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
    
    public enum BehaviorModel: Sendable {
        case normal
        case quiet
    }
    
    enum ContextModel {
        @TaskLocal static var behavior: BehaviorModel = .normal
    }
    
    public static func perform<T>(
        withBehavior behavior: BehaviorModel,
        operation: @Sendable () async throws -> T
    ) async rethrows -> T {
        try await ContextModel.$behavior.withValue(behavior) {
            try await operation()
        }
    }
}

extension LogModel.ConsoleHandlerModel {
    struct EntryModel: Sendable {
        let level: LogModel.LevelModel
        let timestamp: String
        let message: String
        let metadata: [String: String]?
        let file: String
        let function: String
        let line: UInt
    }
}

extension LogModel.ConsoleHandlerModel {
    public actor OutputSinkModel: Sendable {
        public static let shared = OutputSinkModel()
        
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

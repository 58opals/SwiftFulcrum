import Foundation

extension SwiftFulcrum.Logging {
    public struct ConsoleAdapter: SwiftFulcrum.Logging.Adapter {
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

        public func log(_ level: SwiftFulcrum.Logging.Level,
                        _ message: @autoclosure () -> String,
                        metadata: [String : String]?,
                        file: String,
                        function: String,
                        line: UInt) {
            guard SwiftFulcrum.Logging.Context.behavior == .normal else { return }
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
}

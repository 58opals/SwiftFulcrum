// LoggingConsoleAdapterValidator.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct LoggingConsoleAdapterValidator {
    @Test("Quiet behavior suppresses info logs but preserves warnings")
    func quietBehaviorPreservesWarnings() async throws {
        let recorder = ConsoleOutputRecorder()
        let outputSink = SwiftFulcrum.Logging.ConsoleAdapter.OutputSink { line in
            recorder.append(line)
        }
        let logger = SwiftFulcrum.Logging.ConsoleAdapter(
            dateProvider: { Date(timeIntervalSince1970: 0) },
            outputSink: outputSink
        )

        await SwiftFulcrum.Logging.perform(withBehavior: .quiet) {
            logger.log(.info, "quiet.info", metadata: nil, file: "file", function: "function", line: 1)
            logger.log(.warning, "quiet.warning", metadata: nil, file: "file", function: "function", line: 2)
        }

        let didRecordWarning = await waitUntil(timeout: .seconds(1)) {
            recorder.contains("quiet.warning")
        }

        #expect(didRecordWarning)
        #expect(!recorder.contains("quiet.info"))
    }

    @Test("Promotes routing metadata without duplicating it in detail metadata")
    func promoteRoutingMetadata() async throws {
        let recorder = ConsoleOutputRecorder()
        let outputSink = SwiftFulcrum.Logging.ConsoleAdapter.OutputSink { line in
            recorder.append(line)
        }
        let logger = SwiftFulcrum.Logging.ConsoleAdapter(
            dateProvider: { Date(timeIntervalSince1970: 0) },
            outputSink: outputSink
        )

        logger.log(
            .info,
            "metadata.sample",
            metadata: [
                "component": "WebSocketConnection",
                "network": "servers.mainnet",
                "url": "wss://fulcrum.example",
                "detail": "payload"
            ],
            file: "file",
            function: "function",
            line: 1
        )

        let didRecordLine = await waitUntil(timeout: .seconds(1)) {
            recorder.contains("metadata.sample")
        }

        #expect(didRecordLine)
        guard let line = recorder.firstLine(containing: "metadata.sample") else {
            Issue.record("Expected metadata log line")
            return
        }
        #expect(line.contains("[component=WebSocketConnection network=servers.mainnet url=wss://fulcrum.example]"))
        #expect(line.contains("{detail=payload}"))
        #expect(!line.contains("{component="))
    }

    private func waitUntil(
        timeout: Duration,
        pollingInterval: Duration = .milliseconds(25),
        _ condition: @Sendable @escaping () -> Bool
    ) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now + timeout

        while clock.now < deadline {
            if condition() {
                return true
            }
            try? await Task.sleep(for: pollingInterval)
        }

        return condition()
    }
}

private final class ConsoleOutputRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var lines: [String] = .init()

    func append(_ line: String) {
        lock.withLock {
            lines.append(line)
        }
    }

    func contains(_ text: String) -> Bool {
        lock.withLock {
            lines.contains { $0.contains(text) }
        }
    }

    func firstLine(containing text: String) -> String? {
        lock.withLock {
            lines.first { $0.contains(text) }
        }
    }
}

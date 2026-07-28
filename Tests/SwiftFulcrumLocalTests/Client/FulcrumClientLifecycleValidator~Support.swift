// FulcrumClientLifecycleValidator~Support.swift

import Foundation
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    func makeStartedFulcrum() async throws -> (SwiftFulcrum.Client, TransportTestActor) {
        let transport = TransportTestActor()
        let client = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
        let fulcrum = await SwiftFulcrum.Client(client: client)
        try await startAndNegotiate(fulcrum, transport: transport)
        return (fulcrum, transport)
    }

    func startAndNegotiate(_ fulcrum: SwiftFulcrum.Client, transport: TransportTestActor) async throws {
        let startTask = Task { try await fulcrum.start() }

        try await completeProtocolNegotiation(on: transport)
        _ = try await startTask.value
    }

    func decodeRequestObject(_ message: URLSessionWebSocketTask.Message) async throws -> [String: Any] {
        try TransportTestActor.decodeJSONObject(from: message)
    }

    func extractRequestIdentifier(from object: [String: Any]) throws -> String {
        guard let identifier = object["id"] as? String else {
            throw SupportError.missingRequestIdentifier
        }
        return identifier
    }

    func countSentMethodOccurrences(
        _ methodPath: String,
        transport: TransportTestActor
    ) async throws -> Int {
        let messages = await transport.sentMessages
        return try messages.reduce(into: 0) { count, message in
            guard let data = message.dataPayload else { return }
            guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
            if object["method"] as? String == methodPath {
                count += 1
            }
        }
    }

    func waitUntil(
        timeout: Duration,
        pollingInterval: Duration = .milliseconds(25),
        _ condition: @Sendable @escaping () async -> Bool
    ) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now + timeout

        while clock.now < deadline {
            if await condition() {
                return true
            }
            try? await Task.sleep(for: pollingInterval)
        }

        return await condition()
    }

    func collectConnectionStates(
        from stream: AsyncStream<SwiftFulcrum.Client.ConnectionState>,
        count: Int,
        timeout: Duration
    ) async -> [SwiftFulcrum.Client.ConnectionState] {
        let collector = ConnectionStateCollector(targetCount: count)

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                for await state in stream {
                    let reachedTargetCount = await collector.record(state)
                    if reachedTargetCount {
                        break
                    }
                }
            }
            group.addTask {
                try? await Task.sleep(for: timeout)
            }
            _ = await group.next()
            group.cancelAll()
        }

        return await collector.makeSnapshot()
    }

    func detectConnectionStateStreamTermination(
        _ stream: AsyncStream<SwiftFulcrum.Client.ConnectionState>,
        within timeout: Duration
    ) async -> Bool {
        await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                var iterator = stream.makeAsyncIterator()
                while let _ = await iterator.next() {
                    // Keep draining until the stream terminates.
                }
                return true
            }

            group.addTask {
                try? await Task.sleep(for: timeout)
                return false
            }

            let result = await group.next() ?? false
            group.cancelAll()
            return result
        }
    }

    func waitForStreamTerminalError<Stream: AsyncSequence & Sendable>(
        _ stream: Stream,
        within timeout: Duration
    ) async -> Swift.Error? where Stream.Element: Sendable {
        await withTaskGroup(of: Swift.Error?.self) { group in
            group.addTask {
                var iterator = stream.makeAsyncIterator()
                do {
                    while let _ = try await iterator.next() {
                        // Keep draining until the stream terminates.
                    }
                    return nil
                } catch {
                    return error
                }
            }

            group.addTask {
                try? await Task.sleep(for: timeout)
                return SupportError.streamTerminationTimedOut
            }

            let result = await group.next() ?? SupportError.streamTerminationTimedOut
            group.cancelAll()
            return result
        }
    }

    func waitForFirstStreamElement<Stream: AsyncSequence & Sendable>(
        _ stream: Stream,
        within timeout: Duration
    ) async throws -> Stream.Element? where Stream.Element: Sendable {
        try await withThrowingTaskGroup(of: Stream.Element?.self) { group in
            group.addTask {
                var iterator = stream.makeAsyncIterator()
                return try await iterator.next()
            }

            group.addTask {
                try await Task.sleep(for: timeout)
                throw SupportError.streamTerminationTimedOut
            }

            let result = try await group.next() ?? nil
            group.cancelAll()
            return result
        }
    }

}

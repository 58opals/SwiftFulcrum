import Foundation
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    func makeStartedFulcrum() async throws -> (FulcrumClient, TransportTestActor) {
        let transport = TransportTestActor()
        let client = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
        let fulcrum = await FulcrumClient(client: client)
        try await startAndNegotiate(fulcrum, transport: transport)
        return (fulcrum, transport)
    }

    func startAndNegotiate(_ fulcrum: FulcrumClient, transport: TransportTestActor) async throws {
        let startTask = Task { try await fulcrum.start() }

        let versionObject = try await decodeRequestObject(await transport.dequeueOutgoing())
        let versionIdentifier = try requestIdentifier(from: versionObject)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["FulcrumClient 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresObject = try await decodeRequestObject(await transport.dequeueOutgoing())
        let featuresIdentifier = try requestIdentifier(from: featuresObject)
        let featuresPayload = try TransportTestActor.encodeResponsePayload(
            identifier: featuresIdentifier,
            result: [
                "genesis_hash": String(repeating: "0", count: 64),
                "hash_function": "sha256",
                "server_version": "FulcrumClient 2.0",
                "protocol_max": "1.6.0",
                "protocol_min": "1.4.0"
            ]
        )
        await transport.enqueueIncoming(.data(featuresPayload))
        _ = try await startTask.value
    }

    func decodeRequestObject(_ message: URLSessionWebSocketTask.Message) async throws -> [String: Any] {
        try TransportTestActor.decodeJSONObject(from: message)
    }

    func requestIdentifier(from object: [String: Any]) throws -> String {
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
        from stream: AsyncStream<FulcrumClient.ConnectionState>,
        count: Int,
        timeout: Duration
    ) async -> [FulcrumClient.ConnectionState] {
        let collector = ConnectionStateCollectorModel(targetCount: count)

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

        return await collector.snapshot()
    }
    
    func detectConnectionStateStreamTermination(
        _ stream: AsyncStream<FulcrumClient.ConnectionState>,
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

}

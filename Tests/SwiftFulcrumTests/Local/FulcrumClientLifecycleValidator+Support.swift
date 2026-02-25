import Foundation
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    func makeStartedFulcrum() async throws -> (FulcrumClient, TransportTestActor) {
        let transport = TransportTestActor()
        let client = Client(transport: transport, protocolNegotiation: .init())
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

    enum SupportError: Error {
        case missingRequestIdentifier
    }
}

private actor ConnectionStateCollectorModel {
    private let targetCount: Int
    private var states: [FulcrumClient.ConnectionState] = .init()

    init(targetCount: Int) {
        self.targetCount = targetCount
    }

    func record(_ state: FulcrumClient.ConnectionState) -> Bool {
        states.append(state)
        return states.count >= targetCount
    }

    func snapshot() -> [FulcrumClient.ConnectionState] {
        states
    }
}

// FulcrumClientLifecycleValidator~Start.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("reconnect() before start() throws protocol mismatch", .timeLimit(.minutes(1)))
    func reconnectBeforeStartThrowsProtocolMismatch() async {
        let transport = TransportTestActor()
        let client = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
        let fulcrum = await SwiftFulcrum.Client(client: client)

        do {
            try await fulcrum.reconnect()
            Issue.record("reconnect() should throw before start()")
        } catch let error as SwiftFulcrum.Client.Error {
            guard case .client(.protocolMismatch(let message)) = error else {
                Issue.record("Expected protocol mismatch, got \(error)")
                return
            }
            #expect(message == "reconnect() requires start() to succeed before reconnecting.")
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("concurrent start() shares one negotiation attempt", .timeLimit(.minutes(1)))
    func concurrentStartSharesOneNegotiationAttempt() async throws {
        let transport = TransportTestActor()
        await transport.configureConnectDelay(.milliseconds(100))
        let client = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())

        let firstStartTask = Task { try await client.start() }
        try await Task.sleep(for: .milliseconds(10))
        let secondStartTask = Task { try await client.start() }

        let sawVersionRequest = await waitUntil(timeout: .seconds(1)) {
            (try? await countSentMethodOccurrences("server.version", transport: transport)) ?? 0 >= 1
        }
        #expect(sawVersionRequest)

        try await Task.sleep(for: .milliseconds(50))
        let versionRequestCount = try await countSentMethodOccurrences("server.version", transport: transport)
        #expect(versionRequestCount == 1)

        for _ in 0 ..< versionRequestCount {
            let versionObject = try await decodeRequestObject(await transport.dequeueOutgoing())
            #expect(versionObject["method"] as? String == "server.version")
            let versionIdentifier = try extractRequestIdentifier(from: versionObject)
            let versionPayload = try TransportTestActor.encodeResponsePayload(
                identifier: versionIdentifier,
                result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
            )
            await transport.enqueueIncoming(.data(versionPayload))
        }

        let sawFeaturesRequest = await waitUntil(timeout: .seconds(1)) {
            (try? await countSentMethodOccurrences("server.features", transport: transport)) ?? 0 >= versionRequestCount
        }
        #expect(sawFeaturesRequest)

        let featuresRequestCount = try await countSentMethodOccurrences("server.features", transport: transport)
        #expect(featuresRequestCount == versionRequestCount)

        for _ in 0 ..< featuresRequestCount {
            let featuresObject = try await decodeRequestObject(await transport.dequeueOutgoing())
            #expect(featuresObject["method"] as? String == "server.features")
            let featuresIdentifier = try extractRequestIdentifier(from: featuresObject)
            let featuresPayload = try TransportTestActor.encodeResponsePayload(
                identifier: featuresIdentifier,
                result: [
                    "genesis_hash": String(repeating: "0", count: 64),
                    "hash_function": "sha256",
                    "server_version": "SwiftFulcrum.Client 2.0",
                    "protocol_max": "1.6.0",
                    "protocol_min": "1.4.0"
                ]
            )
            await transport.enqueueIncoming(.data(featuresPayload))
        }

        _ = try await firstStartTask.value
        _ = try await secondStartTask.value
        await client.stop()
    }

    @Test("redundant start() does not force protocol renegotiation on the next request", .timeLimit(.minutes(1)))
    func redundantStartDoesNotForceProtocolRenegotiationOnNextRequest() async throws {
        let transport = TransportTestActor()
        let client = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())

        let startTask = Task { try await client.start() }
        let versionObject = try await decodeRequestObject(await transport.dequeueOutgoing())
        let versionIdentifier = try extractRequestIdentifier(from: versionObject)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresObject = try await decodeRequestObject(await transport.dequeueOutgoing())
        let featuresIdentifier = try extractRequestIdentifier(from: featuresObject)
        let featuresPayload = try TransportTestActor.encodeResponsePayload(
            identifier: featuresIdentifier,
            result: [
                "genesis_hash": String(repeating: "0", count: 64),
                "hash_function": "sha256",
                "server_version": "SwiftFulcrum.Client 2.0",
                "protocol_max": "1.6.0",
                "protocol_min": "1.4.0"
            ]
        )
        await transport.enqueueIncoming(.data(featuresPayload))
        _ = try await startTask.value

        let baselineVersionRequestCount = try await countSentMethodOccurrences("server.version", transport: transport)
        #expect(baselineVersionRequestCount == 1)

        try await client.start()

        let requestTask = Task {
            try await client.call(
                method: .blockchain(.headers(.getTip))
            ) as (UUID, SwiftFulcrum.Response.Blockchain.Headers.Tip)
        }

        let firstOutgoing = try await decodeRequestObject(await transport.dequeueOutgoing())
        let firstMethod = firstOutgoing["method"] as? String

        if firstMethod == "server.version" {
            let versionIdentifier = try extractRequestIdentifier(from: firstOutgoing)
            let versionPayload = try TransportTestActor.encodeResponsePayload(
                identifier: versionIdentifier,
                result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
            )
            await transport.enqueueIncoming(.data(versionPayload))

            let featuresObject = try await decodeRequestObject(await transport.dequeueOutgoing())
            #expect(featuresObject["method"] as? String == "server.features")
            let featuresIdentifier = try extractRequestIdentifier(from: featuresObject)
            let featuresPayload = try TransportTestActor.encodeResponsePayload(
                identifier: featuresIdentifier,
                result: [
                    "genesis_hash": String(repeating: "0", count: 64),
                    "hash_function": "sha256",
                    "server_version": "SwiftFulcrum.Client 2.0",
                    "protocol_max": "1.6.0",
                    "protocol_min": "1.4.0"
                ]
            )
            await transport.enqueueIncoming(.data(featuresPayload))
        }

        #expect(firstMethod == SwiftFulcrum.RPC.Method.blockchain(.headers(.getTip)).path)

        let requestObject = firstMethod == SwiftFulcrum.RPC.Method.blockchain(.headers(.getTip)).path
            ? firstOutgoing
            : try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(requestObject["method"] as? String == SwiftFulcrum.RPC.Method.blockchain(.headers(.getTip)).path)

        let requestIdentifier = try extractRequestIdentifier(from: requestObject)
        let requestPayload = try TransportTestActor.encodeResponsePayload(
            identifier: requestIdentifier,
            result: [
                "height": 950_000,
                "hex": String(repeating: "a", count: 160)
            ]
        )
        await transport.enqueueIncoming(.data(requestPayload))

        let (_, response) = try await requestTask.value
        #expect(response.height == 950_000)
        #expect(try await countSentMethodOccurrences("server.version", transport: transport) == baselineVersionRequestCount)

        await client.stop()
    }
}

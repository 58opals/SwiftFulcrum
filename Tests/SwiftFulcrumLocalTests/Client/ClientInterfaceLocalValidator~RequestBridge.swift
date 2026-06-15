// ClientInterfaceLocalValidator~RequestBridge.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ClientInterfaceLocalValidator {
    @Test("Internal unary request bridge rejects subscription methods", .timeLimit(.minutes(1)))
    func rejectSubscriptionMethodsOnRequest() async throws {
        // No network dependency: the internal RPC bridge should reject before attempting to connect.
        let client = try await SwiftFulcrum.Client(connectingTo: try #require(URL(string: "ws://example.com")))

        let subscriptionMethods: [SwiftFulcrum.RPC.Method] = [
            .blockchain(.headers(.subscribe)),
            .blockchain(.address(.subscribe(address: Self.testAddress)))
        ]

        for method in subscriptionMethods {
            do {
                _ = try await client.request(
                    method: method,
                    responseType: SwiftFulcrum.Response.Blockchain.Headers.Tip.self
                )
                Issue.record("request() should reject subscription methods (method: \(method))")
            } catch let error as SwiftFulcrum.Client.Error {
                switch error {
                case .client(.protocolMismatch(let message)):
                    #expect(message?.contains("request() cannot be used with subscription methods") == true)
                default:
                    Issue.record("Unexpected SwiftFulcrum.Client.Error: \(error)")
                }
            } catch {
                Issue.record("Unexpected non-SwiftFulcrum.Client error: \(error)")
            }
        }
    }

    @Test("Unary request starts SwiftFulcrum.Client when idle", .timeLimit(.minutes(1)))
    func requestStartsClientWhenIdle() async throws {
        let transport = TransportTestActor()
        let networkClient = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
        let client = await SwiftFulcrum.Client(client: networkClient)

        let requestTask = Task {
            try await client.request(
                SwiftFulcrum.API.blockchain.headers.tip,
                options: .init(timeout: .seconds(30))
            )
        }

        let versionRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(versionRequest["method"] as? String == "server.version")
        let versionIdentifier = try extractRequestIdentifier(from: versionRequest)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(featuresRequest["method"] as? String == "server.features")
        let featuresIdentifier = try extractRequestIdentifier(from: featuresRequest)
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

        let unaryRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(unaryRequest["method"] as? String == SwiftFulcrum.RPC.Method.blockchain(.headers(.getTip)).path)
        let unaryIdentifier = try extractRequestIdentifier(from: unaryRequest)
        let unaryPayload = try TransportTestActor.encodeResponsePayload(
            identifier: unaryIdentifier,
            result: ["height": 900_000, "hex": String(repeating: "a", count: 160)]
        )
        await transport.enqueueIncoming(.data(unaryPayload))

        let tip = try await requestTask.value
        #expect(tip.height == 900_000)
        #expect(tip.hex.count == 160)
        #expect(await client.isRunning)

        await client.stop()
    }
}

// ClientInterfaceLocalValidator.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct ClientInterfaceLocalValidator {
    private static let testAddress = "bitcoincash:qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx6a"

    @Test("Unary request rejects subscription methods", .timeLimit(.minutes(1)))
    func rejectSubscriptionMethodsOnRequest() async throws {
        // No network dependency: request() should reject before attempting to connect.
        let client = try await SwiftFulcrum.Client(connectingTo: try #require(URL(string: "ws://example.com")))

        let subscriptionMethods: [SwiftFulcrum.RPC.Method] = [
            .blockchain(.headers(.subscribe)),
            .blockchain(.address(.subscribe(address: Self.testAddress)))
        ]

        for method in subscriptionMethods {
            do {
                _ = try await client.request(
                    method: method,
                    responseType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.GetTip.self
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
                method: .blockchain(.headers(.getTip)),
                responseType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.GetTip.self,
                options: .init(timeout: .seconds(30))
            )
        }

        let versionRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(versionRequest["method"] as? String == "server.version")
        let versionIdentifier = try requestIdentifier(from: versionRequest)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(featuresRequest["method"] as? String == "server.features")
        let featuresIdentifier = try requestIdentifier(from: featuresRequest)
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
        let unaryIdentifier = try requestIdentifier(from: unaryRequest)
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

    @Test("subscribe rejects unary methods", .timeLimit(.minutes(1)))
    func rejectUnaryMethodsOnSubscribe() async throws {
        // No network dependency: subscribe() should reject before attempting to connect.
        let client = try await SwiftFulcrum.Client(connectingTo: try #require(URL(string: "ws://example.com")))

        let unaryMethods: [SwiftFulcrum.RPC.Method] = [
            .blockchain(.headers(.getTip)),
            .mempool(.getFeeHistogram)
        ]

        for method in unaryMethods {
            do {
                _ = try await client.subscribe(
                    method: method,
                    initial: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.Subscribe.self,
                    notifications: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.SubscribeNotification.self
                )
                Issue.record("subscribe() should reject unary methods (method: \(method))")
            } catch let error as SwiftFulcrum.Client.Error {
                switch error {
                case .client(.protocolMismatch(let message)):
                    #expect(message?.contains("subscribe() requires subscription methods") == true)
                default:
                    Issue.record("Unexpected SwiftFulcrum.Client.Error: \(error)")
                }
            } catch {
                Issue.record("Unexpected non-SwiftFulcrum.Client error: \(error)")
            }
        }
    }

    @Test("Cancellation cancels underlying token synchronously")
    func markCancellationTokenImmediately() async {
        let cancellation = SwiftFulcrum.Client.Call.Cancellation()

        #expect(await cancellation.isCancelled == false)

        await cancellation.cancel()

        #expect(await cancellation.isCancelled)
    }
}

private extension ClientInterfaceLocalValidator {
    func decodeRequestObject(_ message: URLSessionWebSocketTask.Message) async throws -> [String: Any] {
        try TransportTestActor.decodeJSONObject(from: message)
    }

    func requestIdentifier(from object: [String: Any]) throws -> String {
        guard let identifier = object["id"] as? String else {
            throw SupportError.missingRequestIdentifier
        }

        return identifier
    }

    enum SupportError: Swift.Error {
        case missingRequestIdentifier
    }
}

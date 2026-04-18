// FulcrumClientLifecycleValidator.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct FulcrumClientLifecycleValidator {
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
            let versionIdentifier = try requestIdentifier(from: versionObject)
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
            let featuresIdentifier = try requestIdentifier(from: featuresObject)
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
        let versionIdentifier = try requestIdentifier(from: versionObject)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresObject = try await decodeRequestObject(await transport.dequeueOutgoing())
        let featuresIdentifier = try requestIdentifier(from: featuresObject)
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
            ) as (UUID, SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.GetTip)
        }

        let firstOutgoing = try await decodeRequestObject(await transport.dequeueOutgoing())
        let firstMethod = firstOutgoing["method"] as? String

        if firstMethod == "server.version" {
            let versionIdentifier = try requestIdentifier(from: firstOutgoing)
            let versionPayload = try TransportTestActor.encodeResponsePayload(
                identifier: versionIdentifier,
                result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
            )
            await transport.enqueueIncoming(.data(versionPayload))

            let featuresObject = try await decodeRequestObject(await transport.dequeueOutgoing())
            #expect(featuresObject["method"] as? String == "server.features")
            let featuresIdentifier = try requestIdentifier(from: featuresObject)
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

        let requestIdentifier = try requestIdentifier(from: requestObject)
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

    @Test("request(timeout:) throws timeout when unary response is missing", .timeLimit(.minutes(1)))
    func requestTimeoutWhenUnaryResponseMissing() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()

        let requestTask = Task {
            do {
                _ = try await fulcrum.request(
                    method: .blockchain(.headers(.getTip)),
                    responseType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.GetTip.self,
                    options: .init(timeout: .milliseconds(100))
                )
                Issue.record("request() should time out when response is missing")
            } catch let error as SwiftFulcrum.Client.Error {
                guard case .client(.timeout) = error else {
                    Issue.record("Expected timeout, got \(error)")
                    return
                }
            } catch {
                Issue.record("Unexpected error type: \(error)")
            }
        }

        let request = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(request["method"] as? String == SwiftFulcrum.RPC.Method.blockchain(.headers(.getTip)).path)

        await requestTask.value
        await fulcrum.stop()
    }

    @Test("request(cancellation:) throws cancelled", .timeLimit(.minutes(1)))
    func requestCancellationPropagatesCancelledError() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let cancellation = SwiftFulcrum.Client.Call.Cancellation()

        let requestTask = Task {
            do {
                _ = try await fulcrum.request(
                    method: .blockchain(.headers(.getTip)),
                    responseType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.GetTip.self,
                    options: .init(timeout: .seconds(30), cancellation: cancellation)
                )
                Issue.record("request() should throw cancelled")
            } catch let error as SwiftFulcrum.Client.Error {
                guard case .client(.cancelled) = error else {
                    Issue.record("Expected cancelled, got \(error)")
                    return
                }
            } catch {
                Issue.record("Unexpected error type: \(error)")
            }
        }

        _ = try await decodeRequestObject(await transport.dequeueOutgoing())
        await cancellation.cancel()

        await requestTask.value
        await fulcrum.stop()
    }

    @Test("subscribe(timeout:) cleans up registry", .timeLimit(.minutes(1)))
    func subscribeTimeoutCleansUpSubscriptionRegistry() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()

        let subscribeTask = Task {
            do {
                _ = try await fulcrum.subscribe(
                    method: .blockchain(.headers(.subscribe)),
                    initial: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.Subscribe.self,
                    notifications: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.SubscribeNotification.self,
                    options: .init(timeout: .milliseconds(100))
                )
                Issue.record("subscribe() should time out when initial response is missing")
            } catch let error as SwiftFulcrum.Client.Error {
                guard case .client(.timeout) = error else {
                    Issue.record("Expected timeout, got \(error)")
                    return
                }
            } catch {
                Issue.record("Unexpected error type: \(error)")
            }
        }

        let request = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(request["method"] as? String == SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe)).path)

        await subscribeTask.value

        let snapshot = await fulcrum.makeDiagnosticsSnapshot()
        let subscriptions = await fulcrum.listSubscriptions()
        #expect(snapshot.activeSubscriptionCount == 0)
        #expect(subscriptions.isEmpty)

        await fulcrum.stop()
    }

    @Test("connection state stream publishes idle/connected/disconnected", .timeLimit(.minutes(1)))
    func publishConnectionStateLifecycle() async throws {
        let transport = TransportTestActor()
        let client = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
        let fulcrum = await SwiftFulcrum.Client(client: client)

        let stream = await fulcrum.makeConnectionStateStream()
        let collector = Task { await collectConnectionStates(from: stream, count: 2, timeout: .seconds(2)) }

        try await startAndNegotiate(fulcrum, transport: transport)
        await fulcrum.stop()

        let states = await collector.value
        let idleIndex = states.firstIndex(of: .idle)
        let connectedIndex = states.firstIndex(of: .connected)
        let disconnectedIndex = states.firstIndex(of: .disconnected)

        #expect(idleIndex == 0)
        #expect(connectedIndex != nil)
        #expect(await fulcrum.isRunning == false)
        if let idleIndex, let connectedIndex {
            #expect(idleIndex < connectedIndex)
        }
        if let connectedIndex, let disconnectedIndex {
            #expect(connectedIndex <= disconnectedIndex)
        }
    }
    
    @Test("connection state stream terminates on stop()", .timeLimit(.minutes(1)))
    func connectionStateStreamTerminatesWhenStopped() async throws {
        let (fulcrum, _) = try await makeStartedFulcrum()
        let stream = await fulcrum.makeConnectionStateStream()
        
        await fulcrum.stop()
        
        let terminated = await detectConnectionStateStreamTermination(
            stream,
            within: .seconds(1)
        )
        #expect(terminated)
    }

}

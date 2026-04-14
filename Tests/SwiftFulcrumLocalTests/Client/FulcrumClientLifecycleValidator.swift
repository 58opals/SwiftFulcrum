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

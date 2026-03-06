import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct FulcrumClientLifecycleValidator {
    @Test("submit(timeout:) throws timeout when unary response is missing", .timeLimit(.minutes(1)))
    func submitTimeoutWhenUnaryResponseMissing() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()

        let submitTask = Task {
            do {
                _ = try await fulcrum.submit(
                    method: .blockchain(.headers(.getTip)),
                    responseType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.GetTip.self,
                    options: .init(timeout: .milliseconds(100))
                )
                Issue.record("submit() should time out when response is missing")
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

        await submitTask.value
        await fulcrum.stop()
    }

    @Test("submit(cancellation:) throws cancelled", .timeLimit(.minutes(1)))
    func submitCancellationPropagatesCancelledError() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let cancellation = SwiftFulcrum.Client.Call.Cancellation()

        let submitTask = Task {
            do {
                _ = try await fulcrum.submit(
                    method: .blockchain(.headers(.getTip)),
                    responseType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.GetTip.self,
                    options: .init(timeout: .seconds(30), cancellation: cancellation)
                )
                Issue.record("submit() should throw cancelled")
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

        await submitTask.value
        await fulcrum.stop()
    }

    @Test("subscribe(timeout:) cleans up registry", .timeLimit(.minutes(1)))
    func subscribeTimeoutCleansUpSubscriptionRegistry() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()

        let subscribeTask = Task {
            do {
                _ = try await fulcrum.subscribe(
                    method: .blockchain(.headers(.subscribe)),
                    initialType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.Subscribe.self,
                    notificationType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.SubscribeNotification.self,
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

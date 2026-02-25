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
                    responseType: Response.ResultModel.BlockchainModel.HeadersModel.GetTipModel.self,
                    options: .init(timeout: .milliseconds(100))
                )
                Issue.record("submit() should time out when response is missing")
            } catch let error as FulcrumClient.Error {
                guard case .client(.timeout) = error else {
                    Issue.record("Expected timeout, got \(error)")
                    return
                }
            } catch {
                Issue.record("Unexpected error type: \(error)")
            }
        }

        let request = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(request["method"] as? String == FulcrumMethodRequest.blockchain(.headers(.getTip)).path)

        await submitTask.value
        await fulcrum.stop()
    }

    @Test("submit(cancellation:) throws cancelled", .timeLimit(.minutes(1)))
    func submitCancellationPropagatesCancelledError() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let cancellation = FulcrumClient.CallModel.CancellationModel()

        let submitTask = Task {
            do {
                _ = try await fulcrum.submit(
                    method: .blockchain(.headers(.getTip)),
                    responseType: Response.ResultModel.BlockchainModel.HeadersModel.GetTipModel.self,
                    options: .init(timeout: .seconds(30), cancellation: cancellation)
                )
                Issue.record("submit() should throw cancelled")
            } catch let error as FulcrumClient.Error {
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
                    initialType: Response.ResultModel.BlockchainModel.HeadersModel.SubscribeModel.self,
                    notificationType: Response.ResultModel.BlockchainModel.HeadersModel.SubscribeNotificationModel.self,
                    options: .init(timeout: .milliseconds(100))
                )
                Issue.record("subscribe() should time out when initial response is missing")
            } catch let error as FulcrumClient.Error {
                guard case .client(.timeout) = error else {
                    Issue.record("Expected timeout, got \(error)")
                    return
                }
            } catch {
                Issue.record("Unexpected error type: \(error)")
            }
        }

        let request = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(request["method"] as? String == FulcrumMethodRequest.blockchain(.headers(.subscribe)).path)

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
        let client = Client(transport: transport, protocolNegotiation: .init())
        let fulcrum = await FulcrumClient(client: client)

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

    @Test("diagnostics and subscriptions reflect subscribe/cancel lifecycle", .timeLimit(.minutes(1)))
    func reportDiagnosticsAndSubscriptionLifecycle() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()

        let initialSnapshot = await fulcrum.makeDiagnosticsSnapshot()
        #expect(initialSnapshot.activeSubscriptionCount == 0)
        #expect((await fulcrum.listSubscriptions()).isEmpty)

        let subscribeTask = Task {
            try await fulcrum.subscribe(
                method: .blockchain(.headers(.subscribe)),
                initialType: Response.ResultModel.BlockchainModel.HeadersModel.SubscribeModel.self,
                notificationType: Response.ResultModel.BlockchainModel.HeadersModel.SubscribeNotificationModel.self,
                options: .init(timeout: .seconds(30))
            )
        }

        let request = try await decodeRequestObject(await transport.dequeueOutgoing())
        let identifier = try #require(request["id"] as? String)
        let payload = try TransportTestActor.encodeResponsePayload(
            identifier: identifier,
            result: ["height": 900_000, "hex": String(repeating: "a", count: 160)]
        )
        await transport.enqueueIncoming(.data(payload))

        let (initial, updates, cancel) = try await subscribeTask.value
        #expect(initial.height == 900_000)

        let activeSnapshot = await fulcrum.makeDiagnosticsSnapshot()
        let activeSubscriptions = await fulcrum.listSubscriptions()
        #expect(activeSnapshot.activeSubscriptionCount == 1)
        #expect(activeSubscriptions.count == 1)
        #expect(activeSubscriptions.first?.methodPath == FulcrumMethodRequest.blockchain(.headers(.subscribe)).path)

        await cancel()
        #expect(await NetworkTestClient.detectStreamTermination(updates, within: .seconds(5)))

        let finalSnapshot = await fulcrum.makeDiagnosticsSnapshot()
        #expect(finalSnapshot.activeSubscriptionCount == 0)
        #expect((await fulcrum.listSubscriptions()).isEmpty)

        await fulcrum.stop()
    }
}

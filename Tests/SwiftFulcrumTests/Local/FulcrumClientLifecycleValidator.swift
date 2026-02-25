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
    
    @Test("connection state stream multicasts idle/connected/disconnected to every subscriber", .timeLimit(.minutes(1)))
    func multicastConnectionStateLifecycleToMultipleSubscribers() async throws {
        let transport = TransportTestActor()
        let client = Client(transport: transport, protocolNegotiation: .init())
        let fulcrum = await FulcrumClient(client: client)
        
        let firstStream = await fulcrum.makeConnectionStateStream()
        let secondStream = await fulcrum.makeConnectionStateStream()
        
        let firstCollector = Task {
            await collectConnectionStates(from: firstStream, count: 2, timeout: .seconds(2))
        }
        let secondCollector = Task {
            await collectConnectionStates(from: secondStream, count: 2, timeout: .seconds(2))
        }
        
        try await startAndNegotiate(fulcrum, transport: transport)
        await fulcrum.stop()
        
        let firstStates = await firstCollector.value
        let secondStates = await secondCollector.value
        
        #expect(firstStates == secondStates)
        #expect(firstStates.first == .idle)
        #expect(firstStates.contains(.connected))
        #expect(await fulcrum.isRunning == false)
    }
    
    @Test("stop wins when called during in-flight start", .timeLimit(.minutes(1)))
    func stopWinsWhenCalledDuringInFlightStart() async throws {
        let transport = TransportTestActor()
        await transport.setConnectDelay(.milliseconds(250))
        
        let client = Client(transport: transport, protocolNegotiation: .init())
        let fulcrum = await FulcrumClient(client: client)
        
        let startTask = Task { try await fulcrum.start() }
        
        try await Task.sleep(for: .milliseconds(30))
        await fulcrum.stop()
        
        do {
            try await startTask.value
        } catch is CancellationError {
            // The in-flight start may be cancelled by stop().
        } catch let error as FulcrumClient.Error {
            if case .transport(.connectionClosed) = error {
                // The transport may close during the stop() path.
            } else {
                Issue.record("Unexpected Fulcrum error from start(): \(error)")
            }
        } catch {
            Issue.record("Unexpected error from start(): \(error)")
        }
        
        #expect(await fulcrum.isRunning == false)
        #expect(await fulcrum.connectionState != .connected)
    }
    
    @Test("reconnect renegotiates and resubscribes even without reconnect lifecycle events", .timeLimit(.minutes(1)))
    func reconnectRenegotiatesAndResubscribesWithoutLifecycleEvents() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        
        var subscribeTask: Task<
            (
                Response.ResultModel.BlockchainModel.HeadersModel.SubscribeModel,
                AsyncThrowingStream<Response.ResultModel.BlockchainModel.HeadersModel.SubscribeNotificationModel, Swift.Error>,
                @Sendable () async -> Void
            ),
            Swift.Error
        >? = Task {
            try await fulcrum.subscribe(
                method: .blockchain(.headers(.subscribe)),
                initialType: Response.ResultModel.BlockchainModel.HeadersModel.SubscribeModel.self,
                notificationType: Response.ResultModel.BlockchainModel.HeadersModel.SubscribeNotificationModel.self,
                options: .init(timeout: .seconds(30))
            )
        }
        
        let subscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let subscribeIdentifier = try requestIdentifier(from: subscribeRequest)
        let subscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: subscribeIdentifier,
            result: ["height": 910_000, "hex": String(repeating: "c", count: 160)]
        )
        await transport.enqueueIncoming(.data(subscribePayload))
        let initialSubscription: (
            Response.ResultModel.BlockchainModel.HeadersModel.SubscribeModel,
            AsyncThrowingStream<Response.ResultModel.BlockchainModel.HeadersModel.SubscribeNotificationModel, Swift.Error>,
            @Sendable () async -> Void
        )
        do {
            guard let task = subscribeTask else {
                Issue.record("Subscribe task should exist while awaiting the initial response")
                await fulcrum.stop()
                return
            }
            initialSubscription = try await task.value
        }
        subscribeTask = nil
        let (_, updates, cancel) = initialSubscription
        
        let subscribeMethodPath = FulcrumMethodRequest.blockchain(.headers(.subscribe)).path
        let baselineSubscribeCount = try await countSentMethodOccurrences(
            subscribeMethodPath,
            transport: transport
        )
        
        let reconnectTask = Task {
            try await fulcrum.reconnect()
        }
        
        let versionRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(versionRequest["method"] as? String == "server.version")
        let versionIdentifier = try requestIdentifier(from: versionRequest)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["FulcrumClient 2.0", "1.5.3"]
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
                "server_version": "FulcrumClient 2.0",
                "protocol_max": "1.6.0",
                "protocol_min": "1.4.0"
            ]
        )
        await transport.enqueueIncoming(.data(featuresPayload))
        
        try await reconnectTask.value
        
        let didResubscribe = await waitUntil(timeout: .seconds(2)) {
            let subscribeCount = (try? await countSentMethodOccurrences(
                subscribeMethodPath,
                transport: transport
            )) ?? 0
            return subscribeCount == baselineSubscribeCount + 1
        }
        
        #expect(didResubscribe)
        #expect((await fulcrum.listSubscriptions()).count == 1)
        
        await cancel()
        #expect(await NetworkTestClient.detectStreamTermination(updates, within: .seconds(5)))
        await fulcrum.stop()
    }
    
    @Test("dropping decoded updates stream triggers unsubscribe cleanup", .timeLimit(.minutes(1)))
    func droppingDecodedUpdatesStreamTriggersUnsubscribeCleanup() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        
        var subscribeTask: Task<
            (
                Response.ResultModel.BlockchainModel.HeadersModel.SubscribeModel,
                AsyncThrowingStream<Response.ResultModel.BlockchainModel.HeadersModel.SubscribeNotificationModel, Swift.Error>,
                @Sendable () async -> Void
            ),
            Swift.Error
        >? = Task {
            try await fulcrum.subscribe(
                method: .blockchain(.headers(.subscribe)),
                initialType: Response.ResultModel.BlockchainModel.HeadersModel.SubscribeModel.self,
                notificationType: Response.ResultModel.BlockchainModel.HeadersModel.SubscribeNotificationModel.self,
                options: .init(timeout: .seconds(30))
            )
        }
        
        let subscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let subscribeIdentifier = try requestIdentifier(from: subscribeRequest)
        let subscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: subscribeIdentifier,
            result: ["height": 920_000, "hex": String(repeating: "d", count: 160)]
        )
        await transport.enqueueIncoming(.data(subscribePayload))
        var updatesStream: AsyncThrowingStream<
            Response.ResultModel.BlockchainModel.HeadersModel.SubscribeNotificationModel,
            Swift.Error
        >?
        do {
            guard let task = subscribeTask else {
                Issue.record("Subscribe task should exist while awaiting the initial response")
                await fulcrum.stop()
                return
            }
            let subscription = try await task.value
            #expect(subscription.0.height == 920_000)
            updatesStream = subscription.1
        }
        subscribeTask = nil
        
        let notificationPayload = try TransportTestActor.encodeSubscriptionNotification(
            method: FulcrumMethodRequest.blockchain(.headers(.subscribe)).path,
            parameters: [[
                "height": 920_001,
                "hex": String(repeating: "e", count: 160)
            ]]
        )
        await transport.enqueueIncoming(.data(notificationPayload))
        
        guard updatesStream != nil else {
            Issue.record("Subscription should provide an updates stream")
            await fulcrum.stop()
            return
        }
        var transientUpdatesStream = updatesStream
        updatesStream = nil
        
        var consumeFirstUpdateTask: Task<
            Response.ResultModel.BlockchainModel.HeadersModel.SubscribeNotificationModel?,
            Swift.Error
        >? = Task { [transientUpdatesStream] in
            guard let stream = transientUpdatesStream else { return nil }
            var iterator = stream.makeAsyncIterator()
            return try await iterator.next()
        }
        transientUpdatesStream = nil
        guard let activeConsumeFirstUpdateTask = consumeFirstUpdateTask else {
            Issue.record("Failed to create update-consumer task")
            await fulcrum.stop()
            return
        }
        let firstUpdate = try await activeConsumeFirstUpdateTask.value
        consumeFirstUpdateTask = nil
        #expect(firstUpdate?.blocks.first?.height == 920_001)
        
        let registryDidClear = await waitUntil(timeout: .seconds(5)) {
            (await fulcrum.listSubscriptions()).isEmpty
        }
        #expect(registryDidClear)
        
        let unsubscribeMethodPath = FulcrumMethodRequest.blockchain(.headers(.unsubscribe)).path
        let didSendUnsubscribe = await waitUntil(timeout: .seconds(5)) {
            let unsubscribeCount = (try? await countSentMethodOccurrences(
                unsubscribeMethodPath,
                transport: transport
            )) ?? 0
            return unsubscribeCount > 0
        }
        #expect(didSendUnsubscribe)
        
        await fulcrum.stop()
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

// ClientCancellationValidator.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct ClientCancellationValidator {
    @Test("Shared cancellation cancels every in-flight unary call", .timeLimit(.minutes(1)))
    func sharedCancellationCancelsAllInflightUnaryCalls() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let cancellation = SwiftFulcrum.Client.Call.Cancellation()
        let options = SwiftFulcrum.Client.Call.Options(
            timeout: .milliseconds(250),
            cancellation: cancellation
        )
        
        let firstTask = Task<SwiftFulcrum.Client.Error, Never> {
            do {
                _ = try await fulcrum.request(
                    method: .blockchain(.headers(.getTip)),
                    responseType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.GetTip.self,
                    options: options
                )
                Issue.record("First request should throw cancelled.")
                return .client(.unknown(nil))
            } catch let error as SwiftFulcrum.Client.Error {
                return error
            } catch {
                return .client(.unknown(error))
            }
        }
        
        let secondTask = Task<SwiftFulcrum.Client.Error, Never> {
            do {
                _ = try await fulcrum.request(
                    method: .mempool(.getInfo),
                    responseType: SwiftFulcrum.RPC.Response.Result.Mempool.GetInfo.self,
                    options: options
                )
                Issue.record("Second request should throw cancelled.")
                return .client(.unknown(nil))
            } catch let error as SwiftFulcrum.Client.Error {
                return error
            } catch {
                return .client(.unknown(error))
            }
        }
        
        _ = await transport.dequeueOutgoing()
        _ = await transport.dequeueOutgoing()
        await cancellation.cancel()
        
        let firstError = await firstTask.value
        let secondError = await secondTask.value
        
        #expect(isCancelledError(firstError))
        #expect(isCancelledError(secondError))
        
        await fulcrum.stop()
    }

    @Test("Completed subscriptions unregister shared cancellation handlers", .timeLimit(.minutes(1)))
    func completedSubscriptionsUnregisterSharedCancellationHandlers() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let sharedCancellation = SwiftFulcrum.Client.Call.Cancellation()
        let subscribeMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe))
        let sharedOptions = SwiftFulcrum.Client.Call.Options(
            timeout: .seconds(30),
            cancellation: sharedCancellation
        )

        let firstSubscribeTask = Task {
            try await fulcrum.subscribe(
                method: subscribeMethod,
                initial: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.Subscribe.self,
                notifications: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.SubscribeNotification.self,
                options: sharedOptions
            )
        }

        let firstSubscribeRequest = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        let firstSubscribeIdentifier = try requestIdentifier(from: firstSubscribeRequest)
        let firstSubscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: firstSubscribeIdentifier,
            result: ["height": 940_000, "hex": String(repeating: "a", count: 160)]
        )
        await transport.enqueueIncoming(.data(firstSubscribePayload))

        _ = try await firstSubscribeTask.value

        guard let firstRequestIdentifier = UUID(uuidString: firstSubscribeIdentifier) else {
            Issue.record("First subscription identifier should be a UUID")
            await fulcrum.stop()
            return
        }
        let networkClient = await fulcrum.client
        _ = await networkClient.cleanUpSubscriptionSetup(
            for: .init(methodPath: .headers, identifier: nil),
            requestIdentifier: firstRequestIdentifier
        )

        let didClearFirstSubscription = await waitUntil(timeout: .seconds(2)) {
            (await fulcrum.listSubscriptions()).isEmpty
        }
        #expect(didClearFirstSubscription)

        let secondSubscribeTask = Task {
            try await fulcrum.subscribe(
                method: subscribeMethod,
                initial: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.Subscribe.self,
                notifications: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.SubscribeNotification.self,
                options: .init(timeout: .seconds(30))
            )
        }

        let secondSubscribeRequest = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        let secondSubscribeIdentifier = try requestIdentifier(from: secondSubscribeRequest)
        let secondSubscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: secondSubscribeIdentifier,
            result: ["height": 940_001, "hex": String(repeating: "b", count: 160)]
        )
        await transport.enqueueIncoming(.data(secondSubscribePayload))

        let secondSubscription = try await secondSubscribeTask.value
        #expect((await fulcrum.listSubscriptions()).count == 1)

        await sharedCancellation.cancel()

        let didPreserveSecondSubscription = await waitUntil(timeout: .milliseconds(250)) {
            (await fulcrum.listSubscriptions()).count == 1
        }
        #expect(didPreserveSecondSubscription)

        let notificationPayload = try TransportTestActor.encodeSubscriptionNotification(
            method: subscribeMethod.path,
            parameters: [[
                "height": 940_002,
                "hex": String(repeating: "c", count: 160)
            ]]
        )
        await transport.enqueueIncoming(.data(notificationPayload))

        let update = try await withThrowingTaskGroup(
            of: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.SubscribeNotification?.self
        ) { group in
            group.addTask {
                var iterator = secondSubscription.updates.makeAsyncIterator()
                return try await iterator.next()
            }
            group.addTask {
                try await Task.sleep(for: .milliseconds(500))
                return nil
            }

            let nextUpdate = try await group.next() ?? nil
            group.cancelAll()
            return nextUpdate
        }

        #expect(update?.blocks.first?.height == 940_002)

        await secondSubscription.cancel()
        await fulcrum.stop()
    }
    
    @Test("request(timeout:) does not emit a late request after timeout", .timeLimit(.minutes(1)))
    func requestTimeoutDoesNotEmitLateRequest() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        await transport.configureOutgoingSendDelay(.seconds(1))
        
        let baselineOutgoingCount = await transport.sentMessages.count
        
        let requestTask = Task<SwiftFulcrum.Client.Error, Never> {
            do {
                _ = try await fulcrum.request(
                    method: .blockchain(.headers(.getTip)),
                    responseType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.GetTip.self,
                    options: .init(timeout: .milliseconds(100))
                )
                Issue.record("request() should time out when send is delayed.")
                return .client(.unknown(nil))
            } catch let error as SwiftFulcrum.Client.Error {
                return error
            } catch {
                return .client(.unknown(error))
            }
        }
        
        let error = await requestTask.value
        #expect(isTimeoutError(error))
        
        try? await Task.sleep(for: .milliseconds(1_200))
        let finalOutgoingCount = await transport.sentMessages.count
        #expect(finalOutgoingCount == baselineOutgoingCount)
        
        await fulcrum.stop()
    }

    @Test("request(timeout:) uses one end-to-end budget when starting from idle", .timeLimit(.minutes(1)))
    func requestTimeoutUsesSingleBudgetWhenStartingFromIdle() async throws {
        let transport = TransportTestActor()
        await transport.configureConnectDelay(.milliseconds(120))

        let networkClient = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
        let client = await SwiftFulcrum.Client(client: networkClient)
        let timeout: Duration = .milliseconds(200)

        let requestTask = Task<SwiftFulcrum.Client.Error, Never> {
            do {
                _ = try await client.request(
                    method: .blockchain(.headers(.getTip)),
                    responseType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.GetTip.self,
                    options: .init(timeout: timeout)
                )
                Issue.record("request() should time out after spending the single end-to-end budget.")
                return .client(.unknown(nil))
            } catch let error as SwiftFulcrum.Client.Error {
                return error
            } catch {
                return .client(.unknown(error))
            }
        }

        let versionObject = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        let versionIdentifier = try requestIdentifier(from: versionObject)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresObject = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        let featuresIdentifier = try requestIdentifier(from: featuresObject)
        await transport.configureOutgoingSendDelay(.milliseconds(100))
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

        let error = await requestTask.value
        #expect(error == .client(.timeout(timeout)))

        try? await Task.sleep(for: .milliseconds(250))
        #expect(await transport.sentMessages.count == 2)

        await client.stop()
    }

    @Test("request(task cancellation) does not emit a late request", .timeLimit(.minutes(1)))
    func requestTaskCancellationDoesNotEmitLateRequest() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        await transport.configureOutgoingSendPaused(true)

        let baselineOutgoingCount = await transport.sentMessages.count
        let completion = CancellationCompletionState()

        let requestTask = Task {
            do {
                _ = try await fulcrum.request(
                    method: .blockchain(.headers(.getTip)),
                    responseType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.GetTip.self,
                    options: .init(timeout: .seconds(30))
                )
                Issue.record("request() should throw cancelled when the calling task is cancelled.")
                await completion.finish(with: .client(.unknown(nil)))
            } catch let error as SwiftFulcrum.Client.Error {
                await completion.finish(with: error)
            } catch {
                await completion.finish(with: .client(.unknown(error)))
            }
        }

        let didPauseRequestSend = await waitUntil(timeout: .seconds(2)) {
            await transport.makePendingOutgoingSendCount() == 1
        }
        #expect(didPauseRequestSend)

        requestTask.cancel()
        await transport.configureOutgoingSendPaused(false)

        let didComplete = await waitUntil(timeout: .seconds(2)) {
            await completion.isCompleted
        }
        #expect(didComplete)

        if didComplete {
            #expect(isCancelledError(await completion.recordedError ?? .client(.unknown(nil))))
        }

        try? await Task.sleep(for: .milliseconds(150))
        #expect(await transport.sentMessages.count == baselineOutgoingCount)
        #expect((await fulcrum.makeDiagnosticsSnapshot()).inflightUnaryCallCount == 0)

        await fulcrum.stop()
    }
    
    @Test("subscribe(timeout:) does not emit a late request after timeout", .timeLimit(.minutes(1)))
    func subscribeTimeoutDoesNotEmitLateRequest() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        await transport.configureOutgoingSendDelay(.seconds(1))
        
        let baselineOutgoingCount = await transport.sentMessages.count
        
        let subscribeTask = Task<SwiftFulcrum.Client.Error, Never> {
            do {
                _ = try await fulcrum.subscribe(
                    method: .blockchain(.headers(.subscribe)),
                    initial: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.Subscribe.self,
                    notifications: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.SubscribeNotification.self,
                    options: .init(timeout: .milliseconds(100))
                )
                Issue.record("subscribe() should time out when send is delayed.")
                return .client(.unknown(nil))
            } catch let error as SwiftFulcrum.Client.Error {
                return error
            } catch {
                return .client(.unknown(error))
            }
        }
        
        let error = await subscribeTask.value
        #expect(isTimeoutError(error))
        
        try? await Task.sleep(for: .milliseconds(1_200))
        let finalOutgoingCount = await transport.sentMessages.count
        #expect(finalOutgoingCount == baselineOutgoingCount)
        
        let snapshot = await fulcrum.makeDiagnosticsSnapshot()
        #expect(snapshot.activeSubscriptionCount == 0)
        
        await fulcrum.stop()
    }

    @Test("subscribe(timeout:) uses one end-to-end budget when starting from idle", .timeLimit(.minutes(1)))
    func subscribeTimeoutUsesSingleBudgetWhenStartingFromIdle() async throws {
        let transport = TransportTestActor()
        await transport.configureConnectDelay(.milliseconds(120))

        let networkClient = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
        let client = await SwiftFulcrum.Client(client: networkClient)
        let timeout: Duration = .milliseconds(200)

        let subscribeTask = Task<SwiftFulcrum.Client.Error, Never> {
            do {
                _ = try await client.subscribe(
                    method: .blockchain(.headers(.subscribe)),
                    initial: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.Subscribe.self,
                    notifications: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.SubscribeNotification.self,
                    options: .init(timeout: timeout)
                )
                Issue.record("subscribe() should time out after spending the single end-to-end budget.")
                return .client(.unknown(nil))
            } catch let error as SwiftFulcrum.Client.Error {
                return error
            } catch {
                return .client(.unknown(error))
            }
        }

        let versionObject = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        let versionIdentifier = try requestIdentifier(from: versionObject)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresObject = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        let featuresIdentifier = try requestIdentifier(from: featuresObject)
        await transport.configureOutgoingSendDelay(.milliseconds(100))
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

        let error = await subscribeTask.value
        #expect(error == .client(.timeout(timeout)))

        try? await Task.sleep(for: .milliseconds(250))
        #expect(await transport.sentMessages.count == 2)
        #expect((await client.listSubscriptions()).isEmpty)
        #expect((await client.makeDiagnosticsSnapshot()).activeSubscriptionCount == 0)

        await client.stop()
    }

    @Test("subscribe(task cancellation) does not emit a late request", .timeLimit(.minutes(1)))
    func subscribeTaskCancellationDoesNotEmitLateRequest() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        await transport.configureOutgoingSendPaused(true)

        let baselineOutgoingCount = await transport.sentMessages.count
        let completion = CancellationCompletionState()

        let subscribeTask = Task {
            do {
                _ = try await fulcrum.subscribe(
                    method: .blockchain(.headers(.subscribe)),
                    initial: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.Subscribe.self,
                    notifications: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.SubscribeNotification.self,
                    options: .init(timeout: .seconds(30))
                )
                Issue.record("subscribe() should throw cancelled when the calling task is cancelled.")
                await completion.finish(with: .client(.unknown(nil)))
            } catch let error as SwiftFulcrum.Client.Error {
                await completion.finish(with: error)
            } catch {
                await completion.finish(with: .client(.unknown(error)))
            }
        }

        let didPauseSubscribeSend = await waitUntil(timeout: .seconds(2)) {
            await transport.makePendingOutgoingSendCount() == 1
        }
        #expect(didPauseSubscribeSend)

        subscribeTask.cancel()
        await transport.configureOutgoingSendPaused(false)

        let didComplete = await waitUntil(timeout: .seconds(2)) {
            await completion.isCompleted
        }
        #expect(didComplete)

        if didComplete {
            #expect(isCancelledError(await completion.recordedError ?? .client(.unknown(nil))))
        }

        try? await Task.sleep(for: .milliseconds(150))
        #expect(await transport.sentMessages.count == baselineOutgoingCount)
        let snapshot = await fulcrum.makeDiagnosticsSnapshot()
        #expect(snapshot.activeSubscriptionCount == 0)

        await fulcrum.stop()
    }
}

extension ClientCancellationValidator {
    private func isCancelledError(_ error: SwiftFulcrum.Client.Error) -> Bool {
        if case .client(.cancelled) = error {
            return true
        }
        
        return false
    }
    
    private func isTimeoutError(_ error: SwiftFulcrum.Client.Error) -> Bool {
        if case .client(.timeout) = error {
            return true
        }
        
        return false
    }
    
    func makeStartedFulcrum() async throws -> (SwiftFulcrum.Client, TransportTestActor) {
        let transport = TransportTestActor()
        let client = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
        let fulcrum = await SwiftFulcrum.Client(client: client)
        try await startAndNegotiate(fulcrum, transport: transport)
        return (fulcrum, transport)
    }
    
    private func startAndNegotiate(_ fulcrum: SwiftFulcrum.Client, transport: TransportTestActor) async throws {
        let startTask = Task { try await fulcrum.start() }
        
        let versionObject = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        let versionIdentifier = try requestIdentifier(from: versionObject)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))
        
        let featuresObject = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
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
    }
    
    private func requestIdentifier(from object: [String: Any]) throws -> String {
        guard let identifier = object["id"] as? String else {
            throw SupportError.missingRequestIdentifier
        }
        
        return identifier
    }

    private func waitUntil(
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
    
}

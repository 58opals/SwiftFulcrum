// ClientCancellationValidator~SharedCalls.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ClientCancellationValidator {
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
                    responseType: SwiftFulcrum.Response.Blockchain.Headers.Tip.self,
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
                    responseType: SwiftFulcrum.Response.Mempool.Info.self,
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

    @Test("Pre-cancelled call options do not start an idle client", .timeLimit(.minutes(1)))
    func preCancelledCallOptionsDoNotStartIdleClient() async throws {
        let transport = TransportTestActor()
        let networkClient = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
        let client = await SwiftFulcrum.Client(client: networkClient)
        let cancellation = SwiftFulcrum.Client.Call.Cancellation()
        await cancellation.cancel()

        let requestError = await captureClientError {
            _ = try await client.request(
                SwiftFulcrum.API.blockchain.headers.tip,
                options: .init(timeout: .milliseconds(250), cancellation: cancellation)
            )
        }
        #expect(isCancelledError(requestError))
        #expect(await transport.sentMessages.isEmpty)

        let subscribeError = await captureClientError {
            _ = try await client.subscribe(
                SwiftFulcrum.API.blockchain.headers.subscribe,
                options: .init(timeout: .milliseconds(250), cancellation: cancellation)
            )
        }
        #expect(isCancelledError(subscribeError))
        #expect(await transport.sentMessages.isEmpty)

        await client.stop()
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
                initial: SwiftFulcrum.Response.Blockchain.Headers.Subscribe.self,
                notifications: SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification.self,
                options: sharedOptions
            )
        }

        let firstSubscribeRequest = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        let firstSubscribeIdentifier = try extractRequestIdentifier(from: firstSubscribeRequest)
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
            await fulcrum.makeActiveSubscriptionStates().isEmpty
        }
        #expect(didClearFirstSubscription)

        let secondSubscribeTask = Task {
            try await fulcrum.subscribe(
                method: subscribeMethod,
                initial: SwiftFulcrum.Response.Blockchain.Headers.Subscribe.self,
                notifications: SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification.self,
                options: .init(timeout: .seconds(30))
            )
        }

        let secondSubscribeRequest = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        let secondSubscribeIdentifier = try extractRequestIdentifier(from: secondSubscribeRequest)
        let secondSubscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: secondSubscribeIdentifier,
            result: ["height": 940_001, "hex": String(repeating: "b", count: 160)]
        )
        await transport.enqueueIncoming(.data(secondSubscribePayload))

        let secondSubscription = try await secondSubscribeTask.value
        #expect(await fulcrum.makeActiveSubscriptionCount() == 1)

        await sharedCancellation.cancel()

        let didPreserveSecondSubscription = await waitUntil(timeout: .milliseconds(250)) {
            await fulcrum.makeActiveSubscriptionCount() == 1
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
            of: SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification?.self
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

    @Test("Subscription cancel does not cancel shared call cancellation", .timeLimit(.minutes(1)))
    func subscriptionCancelDoesNotCancelSharedCallCancellation() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let sharedCancellation = SwiftFulcrum.Client.Call.Cancellation()

        let subscribeTask = Task {
            try await fulcrum.subscribe(
                SwiftFulcrum.API.blockchain.headers.subscribe,
                options: .init(timeout: .seconds(30), cancellation: sharedCancellation)
            )
        }

        let subscribeRequest = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        let subscribeIdentifier = try extractRequestIdentifier(from: subscribeRequest)
        let subscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: subscribeIdentifier,
            result: ["height": 940_000, "hex": String(repeating: "a", count: 160)]
        )
        await transport.enqueueIncoming(.data(subscribePayload))

        let subscription = try await subscribeTask.value

        await subscription.cancel()

        #expect(await sharedCancellation.isCancelled == false)
        #expect(await NetworkTestClient.detectStreamTermination(subscription.updates, within: .seconds(5)))

        await fulcrum.stop()
    }

}

// FulcrumClientLifecycleValidator~SubscriptionRouting.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("stale restore registration leaves no unary route", .timeLimit(.minutes(1)))
    func leaveNoUnaryRouteAfterStaleRestoreRegistration() async throws {
        let transport = TransportTestActor()
        let client = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
        let key = FulcrumNetworkClient.SubscriptionKey(methodPath: .headers, identifier: nil)

        try await client.restoreStoredSubscription(
            .blockchain(.headers(.subscribe)),
            for: key,
            reconnectSuccessCount: await transport.reconnectSuccesses
        )

        #expect(await client.makeInflightUnaryCallCount() == 0)
        #expect(await transport.sentMessages.isEmpty)
    }

    @Test("address subscription keys ignore surrounding whitespace", .timeLimit(.minutes(1)))
    func ignoreSurroundingWhitespaceInAddressSubscriptionKeys() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        do {
            let address = " \nbitcoincash:qsubscriptiontest\t "
            let normalizedAddress = "bitcoincash:qsubscriptiontest"
            let endpoint = SwiftFulcrum.API.blockchain.address.subscribe(address: address)

            let subscribeTask = Task {
                try await fulcrum.subscribe(
                    endpoint,
                    options: .init(timeout: .seconds(30))
                )
            }

            let subscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
            let subscribeIdentifier = try extractRequestIdentifier(from: subscribeRequest)
            let subscribePayload = try TransportTestActor.encodeResponsePayload(
                identifier: subscribeIdentifier,
                result: "initial-status"
            )
            await transport.enqueueIncoming(.data(subscribePayload))

            let subscription = try await subscribeTask.value
            #expect(subscription.initial.status == "initial-status")
            let activeSubscription = try #require(await fulcrum.makeActiveSubscriptionStates().first)
            #expect(activeSubscription.identifier == normalizedAddress)

            let notificationPayload = try TransportTestActor.encodeSubscriptionNotification(
                method: endpoint.method.path,
                parameters: [normalizedAddress, "next-status"]
            )
            await transport.enqueueIncoming(.data(notificationPayload))

            let update = try await waitForFirstStreamElement(subscription.updates, within: .seconds(2))
            #expect(update?.subscriptionIdentifier == normalizedAddress)
            #expect(update?.status == "next-status")

            await subscription.cancel()
            let unsubscribePath = SwiftFulcrum.RPC.Method.blockchain(
                .address(.unsubscribe(address: normalizedAddress))
            ).path
            let didSendUnsubscribe = await waitUntil(timeout: .seconds(2)) {
                (try? await self.countSentMethodOccurrences(unsubscribePath, transport: transport)) ?? 0 > 0
            }
            #expect(didSendUnsubscribe)

            let sentMessages = await transport.sentMessages
            var unsubscribeRequest: [String: Any]?
            for message in sentMessages {
                let request = try TransportTestActor.decodeJSONObject(from: message)
                if request["method"] as? String == unsubscribePath {
                    unsubscribeRequest = request
                    break
                }
            }
            let parameters = try #require(unsubscribeRequest?["params"] as? [String])
            #expect(parameters == [normalizedAddress])

            await fulcrum.stop()
        } catch {
            await fulcrum.stop()
            throw error
        }
    }
}

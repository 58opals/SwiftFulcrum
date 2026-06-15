// ClientCancellationValidator~NegotiationOwner.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ClientCancellationValidator {
    @Test("cancelled negotiation owner does not cancel waiting call", .timeLimit(.minutes(1)))
    func cancelledNegotiationOwnerDoesNotCancelWaitingCall() async throws {
        let transport = TransportTestActor()
        let networkClient = FulcrumNetworkClient(transport: transport, protocolNegotiation: .init())
        let fulcrum = await SwiftFulcrum.Client(client: networkClient)
        try await startAndNegotiate(fulcrum, transport: transport)
        await networkClient.resetNegotiatedSession()
        let baselineSentMessageCount = await transport.sentMessages.count
        await transport.configureOutgoingSendPaused(true)
        let ownerCompletion = CancellationCompletionState()

        let ownerCallTask = Task {
            do {
                let _: (UUID, SwiftFulcrum.Response.Server.Ping) = try await networkClient.call(
                    method: .server(.ping),
                    options: .init(timeout: .seconds(30))
                )
                Issue.record("Cancelled negotiation owner should not complete successfully.")
                await ownerCompletion.finish(with: .client(.unknown(nil)))
            } catch let error as SwiftFulcrum.Client.Error {
                await ownerCompletion.finish(with: error)
            } catch {
                await ownerCompletion.finish(with: .client(.unknown(error)))
            }
        }

        let didPauseNegotiationSend = await waitUntil(timeout: .seconds(2)) {
            await transport.makePendingOutgoingSendCount() == 1
        }
        #expect(didPauseNegotiationSend)

        let waiterCallTask = Task {
            try await networkClient.call(
                method: .server(.ping),
                options: .init(timeout: .seconds(30))
            ) as (UUID, SwiftFulcrum.Response.Server.Ping)
        }

        let didRegisterWaitingCall = await waitUntil(timeout: .seconds(2)) {
            await networkClient.state.negotiatedSession.negotiationWaiterCount == 2
        }
        #expect(didRegisterWaitingCall)

        ownerCallTask.cancel()

        let didCancelOwner = await waitUntil(timeout: .seconds(2)) {
            await ownerCompletion.isCompleted
        }
        #expect(didCancelOwner)

        if didCancelOwner {
            #expect(isCancelledError(await ownerCompletion.recordedError ?? .client(.unknown(nil))))
        }

        await transport.configureOutgoingSendPaused(false)

        let didSendVersionRequest = await waitUntil(timeout: .seconds(2)) {
            await transport.sentMessages.count >= baselineSentMessageCount + 1
        }
        #expect(didSendVersionRequest)
        guard didSendVersionRequest else {
            waiterCallTask.cancel()
            _ = try? await waiterCallTask.value
            await fulcrum.stop()
            return
        }

        let versionObject = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        let versionIdentifier = try extractRequestIdentifier(from: versionObject)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let didSendFeaturesRequest = await waitUntil(timeout: .seconds(2)) {
            await transport.sentMessages.count >= baselineSentMessageCount + 2
        }
        #expect(didSendFeaturesRequest)
        guard didSendFeaturesRequest else {
            waiterCallTask.cancel()
            _ = try? await waiterCallTask.value
            await fulcrum.stop()
            return
        }

        let featuresObject = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        let featuresIdentifier = try extractRequestIdentifier(from: featuresObject)
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

        let didSendPingRequest = await waitUntil(timeout: .seconds(2)) {
            await transport.sentMessages.count >= baselineSentMessageCount + 3
        }
        #expect(didSendPingRequest)
        guard didSendPingRequest else {
            waiterCallTask.cancel()
            _ = try? await waiterCallTask.value
            await fulcrum.stop()
            return
        }

        let pingObject = try TransportTestActor.decodeJSONObject(from: await transport.dequeueOutgoing())
        #expect(pingObject["method"] as? String == "server.ping")
        let pingIdentifier = try extractRequestIdentifier(from: pingObject)
        let pingPayload = try TransportTestActor.encodeResponsePayload(
            identifier: pingIdentifier,
            result: NSNull()
        )
        await transport.enqueueIncoming(.data(pingPayload))

        _ = try await waiterCallTask.value
        await fulcrum.stop()
    }
}

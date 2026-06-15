// FulcrumClientLifecycleValidator~ReconnectRestoreSendFailure.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("reconnect restore send failure removes failed subscription", .timeLimit(.minutes(1)))
    func reconnectRestoreSendFailureRemovesFailedSubscription() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let subscribeMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe))

        let subscribeTask = Task<HeadersSubscription, Swift.Error> {
            try await fulcrum.subscribe(method: subscribeMethod, options: .init(timeout: .seconds(30)))
        }

        let subscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let subscribeIdentifier = try extractRequestIdentifier(from: subscribeRequest)
        let subscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: subscribeIdentifier,
            result: ["height": 960_000, "hex": String(repeating: "3", count: 160)]
        )
        await transport.enqueueIncoming(.data(subscribePayload))
        let subscription = try await subscribeTask.value
        let updates = subscription.updates

        let sendFailure = SwiftFulcrum.Client.Error.transport(.reconnectFailed)
        await transport.configureOutgoingSendFailure(sendFailure, forMethodPath: subscribeMethod.path)

        let reconnectTask = Task {
            try await fulcrum.reconnect()
        }

        let versionRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(versionRequest["method"] as? String == "server.version")
        let versionIdentifier = try extractRequestIdentifier(from: versionRequest)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        #expect(featuresRequest["method"] as? String == "server.features")
        let featuresIdentifier = try extractRequestIdentifier(from: featuresRequest)
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

        try await reconnectTask.value

        #expect(await fulcrum.makeActiveSubscriptionStates().isEmpty)

        let terminalError = await waitForStreamTerminalError(updates, within: .seconds(2))
        guard case .transport(.reconnectFailed) = terminalError as? SwiftFulcrum.Client.Error else {
            Issue.record("Expected restore send failure to terminate with reconnectFailed, got \(String(describing: terminalError))")
            await fulcrum.stop()
            return
        }

        await fulcrum.stop()
    }
}

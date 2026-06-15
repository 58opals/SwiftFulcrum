// FulcrumClientLifecycleValidator~ReconnectRestoreFailure.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("reconnect restore error removes failed subscription and preserves others", .timeLimit(.minutes(1)))
    func reconnectRestoreErrorRemovesFailedSubscriptionAndPreservesOthers() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let headersMethod = SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe))
        let scripthashIdentifier = String(repeating: "b", count: 64)
        let scripthashMethod = SwiftFulcrum.RPC.Method.blockchain(.scripthash(.subscribe(scripthash: scripthashIdentifier)))

        let headersSubscribeTask = Task<HeadersSubscription, Swift.Error> {
            try await fulcrum.subscribe(method: headersMethod, options: .init(timeout: .seconds(30)))
        }

        let headersSubscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let headersSubscribeIdentifier = try extractRequestIdentifier(from: headersSubscribeRequest)
        let headersSubscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: headersSubscribeIdentifier,
            result: ["height": 950_000, "hex": String(repeating: "1", count: 160)]
        )
        await transport.enqueueIncoming(.data(headersSubscribePayload))
        let headersSubscription = try await headersSubscribeTask.value
        let headersUpdates = headersSubscription.updates

        let scripthashSubscribeTask = Task<ScriptHashSubscription, Swift.Error> {
            try await fulcrum.subscribe(method: scripthashMethod, options: .init(timeout: .seconds(30)))
        }

        let scripthashSubscribeRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let scripthashSubscribeIdentifier = try extractRequestIdentifier(from: scripthashSubscribeRequest)
        let scripthashSubscribePayload = try TransportTestActor.encodeResponsePayload(
            identifier: scripthashSubscribeIdentifier,
            result: "confirmed-status"
        )
        await transport.enqueueIncoming(.data(scripthashSubscribePayload))
        let scripthashSubscription = try await scripthashSubscribeTask.value
        let scripthashUpdates = scripthashSubscription.updates

        #expect(await fulcrum.makeActiveSubscriptionCount() == 2)

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

        for _ in 0..<2 {
            let restoreRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
            let restoreIdentifier = try extractRequestIdentifier(from: restoreRequest)
            let restoreMethodPath = try #require(restoreRequest["method"] as? String)

            switch restoreMethodPath {
            case headersMethod.path:
                let restorePayload = try TransportTestActor.encodeResponsePayload(
                    identifier: restoreIdentifier,
                    result: ["height": 950_000, "hex": String(repeating: "1", count: 160)]
                )
                await transport.enqueueIncoming(.data(restorePayload))
            case scripthashMethod.path:
                let restorePayload = try TransportTestActor.encodeErrorPayload(
                    identifier: restoreIdentifier,
                    code: -32001,
                    message: "restore rejected"
                )
                await transport.enqueueIncoming(.data(restorePayload))
            default:
                Issue.record("Unexpected restore request: \(restoreMethodPath)")
            }
        }

        try await reconnectTask.value

        let activeSubscriptions = await fulcrum.makeActiveSubscriptionStates()
        #expect(activeSubscriptions.count == 1)
        #expect(activeSubscriptions.first?.methodPath == headersMethod.path)

        let failedRestoreError = await waitForStreamTerminalError(scripthashUpdates, within: .seconds(2))
        guard case .rpc(let serverError) = failedRestoreError as? SwiftFulcrum.Client.Error else {
            Issue.record("Expected failed restore to terminate with RPC error, got \(String(describing: failedRestoreError))")
            await headersSubscription.cancel()
            await fulcrum.stop()
            return
        }
        #expect(serverError.code == -32001)
        #expect(serverError.message == "JSON-RPC server error message redacted (16 UTF-8 bytes)")
        #expect(serverError.messageByteCount == 16)

        let notificationPayload = try TransportTestActor.encodeSubscriptionNotification(
            method: headersMethod.path,
            parameters: [[
                "height": 950_001,
                "hex": String(repeating: "2", count: 160)
            ]]
        )
        await transport.enqueueIncoming(.data(notificationPayload))

        var headersIterator = headersUpdates.makeAsyncIterator()
        let update = try await headersIterator.next()
        #expect(update?.blocks.first?.height == 950_001)

        await headersSubscription.cancel()
        #expect(await NetworkTestClient.detectStreamTermination(headersUpdates, within: .seconds(5)))
        await fulcrum.stop()
    }
}

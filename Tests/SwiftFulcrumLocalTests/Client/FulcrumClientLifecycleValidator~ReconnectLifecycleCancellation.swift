// FulcrumClientLifecycleValidator~ReconnectLifecycleCancellation.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test("manual reconnect cancels active automatic recovery", .timeLimit(.minutes(1)))
    func cancelAutomaticRecoveryBeforeManualReconnect() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()

        try await transport.reconnect(with: nil)
        await transport.configureConnectionState(.connected)
        await transport.enqueueLifecycleEvent(.connected(isReconnect: true))
        let automaticVersionRequest = try await decodeRequestObject(
            await transport.dequeueOutgoing()
        )
        #expect(automaticVersionRequest["method"] as? String == "server.version")

        let reconnectTask = Task {
            try await fulcrum.reconnect()
        }
        let didBeginManualReconnect = await waitUntil(timeout: .seconds(2)) {
            await transport.makeReconnectAttempts() == 2
        }
        #expect(didBeginManualReconnect)

        try await completeProtocolNegotiation(on: transport)
        try await reconnectTask.value

        #expect(await fulcrum.isRunning)
        #expect(await transport.makeReconnectAttempts() == 2)
        await fulcrum.stop()
    }
}

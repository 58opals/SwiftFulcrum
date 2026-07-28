// FulcrumClientLifecycleValidator~ReconnectRouteInvalidation.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    @Test(
        "readiness-started recovery first invalidates old unary calls",
        .timeLimit(.minutes(1))
    )
    func invalidateOldUnaryBeforeReadinessRecovery() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let networkClient = await fulcrum.client
        let requestMethod =
            SwiftFulcrum.RPC.Method.blockchain(.headers(.getTip))

        let requestTask = Task {
            try await fulcrum.request(
                method: requestMethod,
                responseType:
                    SwiftFulcrum.Response.Blockchain.Headers.Tip.self
            )
        }
        _ = await transport.dequeueOutgoing()

        try await transport.reconnect(with: nil)
        await transport.configureConnectionState(.connected)
        let reconnectSuccessCount = await transport.reconnectSuccesses
        let recoveryTask = try #require(
            await networkClient.beginAutomaticReconnectRecovery(
                reconnectSuccessCount: reconnectSuccessCount
            )
        )

        await #expect(throws: SwiftFulcrum.Client.Error.self) {
            try await requestTask.value
        }
        try await completeProtocolNegotiation(on: transport)
        try await recoveryTask.value

        await fulcrum.stop()
    }

    @Test(
        "successful reconnect fails unary calls lost with the old socket",
        .timeLimit(.minutes(1))
    )
    func failUnaryCallLostDuringReconnect() async throws {
        let (fulcrum, transport) = try await makeStartedFulcrum()
        let networkClient = await fulcrum.client
        let requestMethod =
            SwiftFulcrum.RPC.Method.blockchain(.headers(.getTip))

        let requestTask = Task {
            try await fulcrum.request(
                method: requestMethod,
                responseType:
                    SwiftFulcrum.Response.Blockchain.Headers.Tip.self
            )
        }
        let request = try await decodeRequestObject(
            await transport.dequeueOutgoing()
        )
        #expect(request["method"] as? String == requestMethod.path)

        try await transport.reconnect(with: nil)
        await transport.configureConnectionState(.connected)
        await transport.enqueueLifecycleEvent(
            .connected(isReconnect: true)
        )

        await #expect(throws: SwiftFulcrum.Client.Error.self) {
            try await requestTask.value
        }

        try await completeProtocolNegotiation(on: transport)
        let recoveryTask = try #require(
            await networkClient.reconnectRecoveryState.recoveryTask
        )
        try await recoveryTask.value

        await fulcrum.stop()
    }
}

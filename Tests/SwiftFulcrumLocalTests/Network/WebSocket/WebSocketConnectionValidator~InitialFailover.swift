// WebSocketConnectionValidator~InitialFailover.swift

import Foundation
import Testing
@testable import SwiftFulcrum

extension WebSocketConnectionValidator {
    @Test("finite initial failover preserves its exhaustion error", .timeLimit(.minutes(1)))
    func preserveFiniteInitialFailoverExhaustionError() async throws {
        let hangingServer = try LocalHangingTCPServer()
        let endpoint = try await hangingServer.start()
        let webSocket = WebSocketConnection(
            url: endpoint,
            configuration: .init(
                bootstrapServers: [endpoint],
                serverCatalogLoader: .makeConstant([endpoint])
            ),
            reconnectConfiguration: .init(
                maximumReconnectionAttempts: 1,
                reconnectionDelay: 0,
                maximumDelay: 0,
                jitterRange: 1 ... 1
            ),
            connectionTimeout: 0.01
        )

        do {
            try await webSocket.connect()
            Issue.record("Expected initial failover to exhaust")
        } catch let error as SwiftFulcrum.Client.Error {
            if case .transport(.connectionClosed(let code, let reason)) = error {
                #expect(code == .goingAway)
                #expect(reason == "Reconnection attempts exhausted.")
            } else {
                Issue.record("Expected a connection-closed exhaustion error, got \(error)")
            }
        } catch {
            Issue.record("Expected SwiftFulcrum.Client.Error, got \(error)")
        }

        let session = await webSocket.session
        session.invalidateAndCancel()
        await hangingServer.stop()
    }
}

// WebSocketConnectionValidator~ConnectTimeout.swift

import Foundation
import Network
import OpalDiagnostics
import Testing
@testable import SwiftFulcrum

extension WebSocketConnectionValidator {
    @Test("connect timeout preserves the timeout close reason", .timeLimit(.minutes(1)))
    func connectTimeoutPreservesTimeoutCloseReason() async throws {
        let hangingServer = try LocalHangingTCPServer()
        let endpoint = try await hangingServer.start()
        defer {
            let server = hangingServer
            Task { await server.stop() }
        }

        let webSocket = WebSocketConnection(
            url: endpoint,
            connectionTimeout: 0.05
        )

        try await OpalDiagnostics.withConfiguration(Self.diagnosticsConfiguration) {
            OpalDiagnostics.clearRecentRecords()

            do {
                try await webSocket.connect(shouldAllowFailover: false)
                Issue.record("Expected connect() to fail when the socket never opens")
            } catch let error as SwiftFulcrum.Client.Error {
                guard case .transport(.connectionClosed(let code, let reason)) = error else {
                    Issue.record("Expected connectionClosed timeout error, got \(error)")
                    return
                }

                #expect(code == .goingAway)
                #expect(reason == "Connection timed out.")
            }

            let timeoutRecord = try #require(
                OpalDiagnostics.recentRecords(
                    matching: .init(event: OpalDiagnostics.Event.swiftFulcrumWebSocketConnectTimeout)
                ).first
            )
            #expect(timeoutRecord.category == OpalDiagnostics.Category.swiftFulcrumWebSocket)
            timeoutRecord.expectErrorCode(.clientTimeout)
            #expect(findField("reason", in: timeoutRecord)?.value == "<redacted>")
        }

        let session = await webSocket.session
        session.invalidateAndCancel()
    }
}

extension WebSocketConnectionValidator {
}

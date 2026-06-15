// TransportTestActor~Lifecycle.swift

import Foundation
@testable import SwiftFulcrum

extension TransportTestActor {
    func connect() async throws {
        try await applyConnectDelayIfNeeded()
        updateConnectionState(to: .connected)
        enqueueLifecycleEvent(.connected(isReconnect: false))
    }

    func disconnect(with reason: String?) async {
        closeInformationValue = (.normalClosure, reason)
        updateConnectionState(to: .disconnected)
        enqueueLifecycleEvent(.disconnected(code: .normalClosure, reason: reason))
    }

    func reconnect(with url: URL?) async throws {
        reconnectAttempts += 1
        if let reconnectFailure {
            throw reconnectFailure
        }
        reconnectSuccesses += 1
        if let url { currentEndpoint = url }
        updateConnectionState(to: .reconnecting)
    }

    func updateConnectionState(to newState: SwiftFulcrum.Client.ConnectionState) {
        guard connectionStateValue != newState else { return }
        connectionStateValue = newState
        connectionStateBuffer.append(newState)
        flushConnectionStateBuffer()
    }

    func apply(_ event: SwiftFulcrum.Transport.State.Event) {
        switch event {
        case .connected(let isReconnect):
            if isReconnect { updateConnectionState(to: .reconnecting) }
            updateConnectionState(to: .connected)
        case .disconnected(let code, let reason):
            closeInformationValue = (code, reason)
            updateConnectionState(to: .disconnected)
        }
    }
}

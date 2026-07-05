// WebSocketConnection.Reconnector+ReconnectionAttempt.swift

import Foundation

extension WebSocketConnection.Reconnector {
    struct ReconnectionAttempt: Sendable {
        let receiverCancellation: WebSocketConnection.ReceiverCancellation
        let connectedLifecycleEvent: WebSocketConnection.Lifecycle.Event
        let diagnosticsPhase: String

        static let initialConnection = Self(
            receiverCancellation: .cancel,
            connectedLifecycleEvent: .connected(isReconnect: false),
            diagnosticsPhase: "initial"
        )

        static let manualReconnect = Self(
            receiverCancellation: .preserve,
            connectedLifecycleEvent: .connected(isReconnect: true),
            diagnosticsPhase: "reconnect"
        )

        static let automaticReconnect = Self(
            receiverCancellation: .preserve,
            connectedLifecycleEvent: .connected(isReconnect: true),
            diagnosticsPhase: "reconnect"
        )

        var connectionAttempt: WebSocketConnection.ConnectionAttempt {
            switch receiverCancellation {
            case .cancel:
                return .reconnectCandidate
            case .preserve:
                return .reconnectCandidatePreservingReceiver
            }
        }
    }
}

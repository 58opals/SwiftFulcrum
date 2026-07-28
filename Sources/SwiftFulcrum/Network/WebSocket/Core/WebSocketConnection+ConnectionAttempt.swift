// WebSocketConnection+ConnectionAttempt.swift

import Foundation

extension WebSocketConnection {
    struct ConnectionAttempt: Sendable {
        let connectedLifecycleEvent: Lifecycle.Event?
        let allowsFailover: Bool
        let shouldRecordReconnectSuccess: Bool
        let receiverCancellation: ReceiverCancellation
        let failureState: ConnectionState

        static let initial = Self(
            connectedLifecycleEvent: .connected(isReconnect: false),
            allowsFailover: true,
            shouldRecordReconnectSuccess: false,
            receiverCancellation: .cancel,
            failureState: .disconnected
        )

        static let initialWithoutFailover = Self(
            connectedLifecycleEvent: .connected(isReconnect: false),
            allowsFailover: false,
            shouldRecordReconnectSuccess: false,
            receiverCancellation: .cancel,
            failureState: .disconnected
        )

        static let reconnectCandidate = Self(
            connectedLifecycleEvent: nil,
            allowsFailover: false,
            shouldRecordReconnectSuccess: true,
            receiverCancellation: .cancel,
            failureState: .reconnecting
        )

        static let reconnectCandidatePreservingReceiver = Self(
            connectedLifecycleEvent: nil,
            allowsFailover: false,
            shouldRecordReconnectSuccess: true,
            receiverCancellation: .preserve,
            failureState: .reconnecting
        )
    }
}

// TransportTestActor~Configuration.swift

import Foundation
@testable import SwiftFulcrum

extension TransportTestActor {
    func configureReconnectFailure(_ error: Swift.Error?) {
        reconnectFailure = error
    }

    func configureOutgoingSendDelay(_ delay: Duration?) {
        outgoingSendDelay = delay
    }

    func configureOutgoingSendPaused(_ isPaused: Bool) {
        shouldPauseOutgoingSend = isPaused
        if !isPaused {
            resumePendingOutgoingSends()
        }
    }

    func configureOutgoingSendFailure(_ error: Swift.Error?, forMethodPath methodPath: String) {
        if let error {
            outgoingSendFailuresByMethodPath[methodPath] = error
        } else {
            outgoingSendFailuresByMethodPath.removeValue(forKey: methodPath)
        }
    }

    func configureConnectDelay(_ delay: Duration?) {
        connectDelay = delay
    }

    func configureDisconnectPaused(_ isPaused: Bool) {
        shouldPauseDisconnect = isPaused
        if !isPaused {
            let continuations = pendingDisconnectContinuations
            pendingDisconnectContinuations.removeAll(keepingCapacity: false)
            for continuation in continuations {
                continuation.resume()
            }
        }
    }

    func configureConnectionState(_ state: SwiftFulcrum.Client.ConnectionState) {
        updateConnectionState(to: state)
    }

    func pauseNextConnectionStateRead() {
        shouldPauseNextConnectionStateRead = true
    }

    func resumePendingConnectionStateReads() {
        let continuations = pendingConnectionStateReadContinuations
        pendingConnectionStateReadContinuations.removeAll(keepingCapacity: false)
        for continuation in continuations {
            continuation.resume()
        }
    }

    func pauseEndpointRead(afterUnpausedReads: Int = 0) {
        endpointReadsBeforePause = afterUnpausedReads
    }

    func resumePendingEndpointReads(pausingNextRead: Bool = false) {
        if pausingNextRead {
            endpointReadsBeforePause = 0
        }
        let continuations = pendingEndpointReadContinuations
        pendingEndpointReadContinuations.removeAll(keepingCapacity: false)
        for continuation in continuations {
            continuation.resume()
        }
    }

    func pauseReconnectSuccessRead(afterUnpausedReads: Int = 0) {
        reconnectSuccessReadsBeforePause = afterUnpausedReads
    }

    func resumePendingReconnectSuccessReads() {
        let continuations = pendingReconnectSuccessReadContinuations
        pendingReconnectSuccessReadContinuations.removeAll(
            keepingCapacity: false
        )
        for continuation in continuations {
            continuation.resume()
        }
    }

    func makeReconnectAttempts() -> Int {
        reconnectAttempts
    }

    func makePendingOutgoingSendCount() -> Int {
        pendingOutgoingSendGateContinuations.count
    }

    func makePendingDisconnectCount() -> Int {
        pendingDisconnectContinuations.count
    }

    func makePendingConnectionStateReadCount() -> Int {
        pendingConnectionStateReadContinuations.count
    }

    func makePendingEndpointReadCount() -> Int {
        pendingEndpointReadContinuations.count
    }

    func makePendingReconnectSuccessReadCount() -> Int {
        pendingReconnectSuccessReadContinuations.count
    }
}

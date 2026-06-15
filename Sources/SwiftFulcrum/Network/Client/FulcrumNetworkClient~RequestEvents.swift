// FulcrumNetworkClient~RequestEvents.swift

import Foundation
import OpalDiagnostics

extension FulcrumNetworkClient {
    func callFailureEvent(
        for error: Swift.Error,
        timeoutState: RequestTimeoutState
    ) async -> OpalDiagnostics.Event {
        if await timeoutState.timeoutError != nil || isTimeoutError(error) {
            return OpalDiagnostics.Event.swiftFulcrumClientCallTimeout
        }

        if isCancellationError(error) {
            return OpalDiagnostics.Event.swiftFulcrumClientCallCancelled
        }

        return OpalDiagnostics.Event.swiftFulcrumClientCallFailed
    }

    func subscribeFailureEvent(
        for error: Swift.Error,
        timeoutState: RequestTimeoutState
    ) async -> OpalDiagnostics.Event {
        if await timeoutState.timeoutError != nil || isTimeoutError(error) {
            return OpalDiagnostics.Event.swiftFulcrumClientSubscribeTimeout
        }

        if isCancellationError(error) {
            return OpalDiagnostics.Event.swiftFulcrumClientSubscribeCancelled
        }

        return OpalDiagnostics.Event.swiftFulcrumClientSubscribeFailed
    }

    func isCancellationError(_ error: Swift.Error) -> Bool {
        if error is CancellationError { return true }
        if let clientError = error as? SwiftFulcrum.Client.Error,
           clientError == .client(.cancelled) {
            return true
        }
        return false
    }

    func isTimeoutError(_ error: Swift.Error) -> Bool {
        if let clientError = error as? SwiftFulcrum.Client.Error,
           case .client(.timeout(_)) = clientError {
            return true
        }
        return false
    }
}

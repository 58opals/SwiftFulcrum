// FulcrumNetworkClient+ReconnectRecoveryState.swift

import Foundation

extension FulcrumNetworkClient {
    enum ReconnectRecoveryState: Sendable {
        case idle
        case needed
        case waitingForConnection
        case recovering(Task<Void, Swift.Error>)

        var recoveryTask: Task<Void, Swift.Error>? {
            guard case .recovering(let task) = self else { return nil }
            return task
        }

        var needsRecovery: Bool {
            switch self {
            case .needed, .waitingForConnection, .recovering:
                return true
            case .idle:
                return false
            }
        }
    }
}

// FulcrumNetworkClient+SubscriptionLifecyclePhase.swift

import Foundation

extension FulcrumNetworkClient {
    enum SubscriptionLifecyclePhase: Sendable {
        case pending(requestIdentifier: UUID)
        case settingUp(requestIdentifier: UUID, task: Task<Void, Swift.Error>?)
        case active(requestIdentifier: UUID)

        var requestIdentifier: UUID {
            switch self {
            case .pending(let requestIdentifier),
                 .settingUp(let requestIdentifier, _),
                 .active(let requestIdentifier):
                requestIdentifier
            }
        }

        var setupTask: Task<Void, Swift.Error>? {
            guard case .settingUp(_, let task) = self else { return nil }
            return task
        }

        var isRoutable: Bool {
            switch self {
            case .pending:
                return false
            case .settingUp, .active:
                return true
            }
        }

        var allowsUnsubscribeOnCancellation: Bool {
            guard case .active = self else { return false }
            return true
        }
    }
}

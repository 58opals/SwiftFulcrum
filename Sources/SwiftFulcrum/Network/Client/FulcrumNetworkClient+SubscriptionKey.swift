// FulcrumNetworkClient+SubscriptionKey.swift

import Foundation

extension FulcrumNetworkClient {
    struct SubscriptionKey {
        let methodPath: SubscriptionPathConfiguration
        let identifier: String?

        var string: String { identifier.map {"\(methodPath.rawValue):\($0)"} ?? methodPath.rawValue }
    }
}

extension FulcrumNetworkClient.SubscriptionKey: Hashable, Sendable {}

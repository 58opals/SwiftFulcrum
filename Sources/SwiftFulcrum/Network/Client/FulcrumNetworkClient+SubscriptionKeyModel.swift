// FulcrumNetworkClient+SubscriptionKeyModel.swift

import Foundation

extension FulcrumNetworkClient {
    struct SubscriptionKeyModel {
        let methodPath: SubscriptionPathConfiguration
        let identifier: String?

        var string: String { identifier.map {"\(methodPath.rawValue):\($0)"} ?? methodPath.rawValue }
    }
}

extension FulcrumNetworkClient.SubscriptionKeyModel: Hashable, Sendable {}

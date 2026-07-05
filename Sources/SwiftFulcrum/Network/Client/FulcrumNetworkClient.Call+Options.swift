// FulcrumNetworkClient.Call+Options.swift

import Foundation

extension FulcrumNetworkClient.Call {
    struct Options: Sendable {
        public var timeout: Duration?
        public var token: FulcrumNetworkClient.Call.Token?
        public var subscriptionBufferPolicy: SwiftFulcrum.Client.SubscriptionBufferPolicy

        init(
            timeout: Duration? = nil,
            token: FulcrumNetworkClient.Call.Token? = nil,
            subscriptionBufferPolicy: SwiftFulcrum.Client.SubscriptionBufferPolicy = .defaultPolicy
        ) {
            self.timeout = timeout
            self.token = token
            self.subscriptionBufferPolicy = subscriptionBufferPolicy
        }
    }
}

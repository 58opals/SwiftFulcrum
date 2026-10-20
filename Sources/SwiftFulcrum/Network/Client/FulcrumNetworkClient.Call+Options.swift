// FulcrumNetworkClient.Call+Options.swift

import Foundation

extension FulcrumNetworkClient.Call {
    struct Options: Sendable {
        public var timeout: Duration?
        public var token: FulcrumNetworkClient.Call.Token?
        public var subscriptionBufferPolicy: SwiftFulcrum.Client.SubscriptionBufferPolicy
        public var sendAuthorization: SwiftFulcrum.Client.Call.SendAuthorization?

        init(
            timeout: Duration? = nil,
            token: FulcrumNetworkClient.Call.Token? = nil,
            subscriptionBufferPolicy: SwiftFulcrum.Client.SubscriptionBufferPolicy = .defaultPolicy,
            sendAuthorization: SwiftFulcrum.Client.Call.SendAuthorization? = nil
        ) {
            self.timeout = timeout
            self.token = token
            self.subscriptionBufferPolicy = subscriptionBufferPolicy
            self.sendAuthorization = sendAuthorization
        }
    }
}

// Client.Call+Options.swift

import Foundation

extension SwiftFulcrum.Client.Call {
    public struct Options: Sendable {
        public var timeout: Duration?
        public var cancellation: Cancellation?
        public var subscriptionBufferPolicy: SwiftFulcrum.Client.SubscriptionBufferPolicy

        public init(
            timeout: Duration? = nil,
            cancellation: Cancellation? = nil,
            subscriptionBufferPolicy: SwiftFulcrum.Client.SubscriptionBufferPolicy = .defaultPolicy
        ) {
            self.timeout = timeout
            self.cancellation = cancellation
            self.subscriptionBufferPolicy = subscriptionBufferPolicy
        }
    }
}

extension SwiftFulcrum.Client.Call.Options {
    var clientOptions: FulcrumNetworkClient.Call.Options {
        .init(timeout: timeout, token: cancellation?.token, subscriptionBufferPolicy: subscriptionBufferPolicy)
    }
}

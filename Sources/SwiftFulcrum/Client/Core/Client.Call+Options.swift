// Client.Call+Options.swift

import Foundation

extension SwiftFulcrum.Client.Call {
    public struct Options: Sendable {
        public var timeout: Duration?
        public var cancellation: Cancellation?
        public var subscriptionBufferPolicy: SwiftFulcrum.Client.SubscriptionBufferPolicy
        public var sendAuthorization: SendAuthorization?

        public init(
            timeout: Duration? = nil,
            cancellation: Cancellation? = nil,
            subscriptionBufferPolicy: SwiftFulcrum.Client.SubscriptionBufferPolicy = .defaultPolicy,
            sendAuthorization: SendAuthorization? = nil
        ) {
            self.timeout = timeout
            self.cancellation = cancellation
            self.subscriptionBufferPolicy = subscriptionBufferPolicy
            self.sendAuthorization = sendAuthorization
        }
    }
}

extension SwiftFulcrum.Client.Call.Options {
    var clientOptions: FulcrumNetworkClient.Call.Options {
        .init(timeout: timeout, token: cancellation?.token,
            subscriptionBufferPolicy: subscriptionBufferPolicy, sendAuthorization: sendAuthorization)
    }
}

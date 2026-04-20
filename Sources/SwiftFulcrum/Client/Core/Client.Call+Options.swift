// Client.Call+Options.swift

import Foundation

extension SwiftFulcrum.Client.Call {
    public struct Options: Sendable {
        public var timeout: Duration?
        public var cancellation: Cancellation?

        public init(timeout: Duration? = nil, cancellation: Cancellation? = nil) {
            self.timeout = timeout
            self.cancellation = cancellation
        }
    }
}

extension SwiftFulcrum.Client.Call.Options {
    var clientOptions: FulcrumNetworkClient.Call.Options {
        .init(timeout: timeout, token: cancellation?.token)
    }
}

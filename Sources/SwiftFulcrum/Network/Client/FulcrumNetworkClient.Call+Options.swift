// FulcrumNetworkClient.Call+Options.swift

import Foundation

extension FulcrumNetworkClient.Call {
    struct Options: Sendable {
        public var timeout: Duration?
        public var token: FulcrumNetworkClient.Call.Token?

        init(timeout: Duration? = nil, token: FulcrumNetworkClient.Call.Token? = nil) {
            self.timeout = timeout
            self.token = token
        }
    }
}

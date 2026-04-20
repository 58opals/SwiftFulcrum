// Client.Call+Cancellation.swift

import Foundation

extension SwiftFulcrum.Client.Call {
    public actor Cancellation: Sendable {
        let token: FulcrumNetworkClient.Call.Token

        public init() {
            self.token = .init()
        }

        public func cancel() async {
            await token.cancel()
        }

        public var isCancelled: Bool {
            get async { await token.isCancelled }
        }
    }
}

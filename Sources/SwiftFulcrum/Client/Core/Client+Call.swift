// Client+Call.swift

import Foundation

extension SwiftFulcrum.Client {
    public enum Call {}
}

extension SwiftFulcrum.Client.Call {
    public struct Options: Sendable {
        public var timeout: Duration?
        public var cancellation: Cancellation?
        
        public init(timeout: Duration? = nil, cancellation: Cancellation? = nil) {
            self.timeout = timeout
            self.cancellation = cancellation
        }
    }
    
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

extension SwiftFulcrum.Client.Call.Options {
    var clientOptions: FulcrumNetworkClient.Call.Options {
        .init(timeout: timeout, token: cancellation?.token)
    }
}

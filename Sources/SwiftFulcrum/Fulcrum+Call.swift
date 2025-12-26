// Fulcrum+Call.swift

import Foundation

extension Fulcrum {
    public enum Call {}
}

extension Fulcrum.Call {
    public struct Options: Sendable {
        public var timeout: Duration?
        public var cancellation: Cancellation?
        
        public init(timeout: Duration? = nil, cancellation: Cancellation? = nil) {
            self.timeout = timeout
            self.cancellation = cancellation
        }
    }
    
    public actor Cancellation: Sendable {
        let token: Client.Call.Token
        
        public init() {
            self.token = .init()
        }
        
        public func cancel() async {
            await token.cancel()
        }
        
        public func isCancelled() async -> Bool {
            await token.isCancelled
        }
    }
}

extension Fulcrum.Call.Options {
    var clientOptions: Client.Call.Options {
        .init(timeout: timeout, token: cancellation?.token)
    }
}

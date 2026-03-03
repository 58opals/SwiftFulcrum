// FulcrumClient+CallModel.swift

import Foundation

extension FulcrumClient {
    public enum CallModel {}
}

extension FulcrumClient.CallModel {
    public struct Options: Sendable {
        public var timeout: Duration?
        public var cancellation: Cancellation?
        
        public init(timeout: Duration? = nil, cancellation: Cancellation? = nil) {
            self.timeout = timeout
            self.cancellation = cancellation
        }
    }
    
    public actor Cancellation: Sendable {
        let token: FulcrumNetworkClient.CallModel.Token
        
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

extension FulcrumClient.CallModel.Options {
    var clientOptions: FulcrumNetworkClient.CallModel.Options {
        .init(timeout: timeout, token: cancellation?.token)
    }
}

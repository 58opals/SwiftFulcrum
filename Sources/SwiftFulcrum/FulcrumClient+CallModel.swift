// FulcrumClient+CallModel.swift

import Foundation

extension FulcrumClient {
    public enum CallModel {}
}

extension FulcrumClient.CallModel {
    public struct OptionsModel: Sendable {
        public var timeout: Duration?
        public var cancellation: CancellationModel?
        
        public init(timeout: Duration? = nil, cancellation: CancellationModel? = nil) {
            self.timeout = timeout
            self.cancellation = cancellation
        }
    }
    
    public actor CancellationModel: Sendable {
        let token: Client.CallModel.TokenModel
        
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

extension FulcrumClient.CallModel.OptionsModel {
    var clientOptions: Client.CallModel.OptionsModel {
        .init(timeout: timeout, token: cancellation?.token)
    }
}

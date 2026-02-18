// Client+CallModel.swift

import Foundation

extension Client {
    enum CallModel {}
}

extension Client.CallModel {
    struct OptionsModel: Sendable {
        public var timeout: Duration?
        public var token: Client.CallModel.TokenModel?
        
        init(timeout: Duration? = nil, token: Client.CallModel.TokenModel? = nil) {
            self.timeout = timeout
            self.token = token
        }
    }
    
    actor TokenModel {
        private var handler: (@Sendable () -> Void)?
        private var isCancellationRequested = false
        
        init() {}
        
        func register(_ handler: @escaping @Sendable () -> Void) {
            if isCancellationRequested { handler() } else { self.handler = handler }
        }
        
        public func cancel() { isCancellationRequested = true; handler?() }
        public var isCancelled: Bool { isCancellationRequested }
    }
}

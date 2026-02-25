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
        private var handlers: [@Sendable () -> Void] = .init()
        private var isCancellationRequested = false
        
        init() {}
        
        func register(_ handler: @escaping @Sendable () -> Void) {
            if isCancellationRequested {
                handler()
            } else {
                handlers.append(handler)
            }
        }
        
        public func cancel() {
            guard !isCancellationRequested else { return }
            
            isCancellationRequested = true
            let registeredHandlers = handlers
            handlers.removeAll(keepingCapacity: false)
            
            for handler in registeredHandlers {
                handler()
            }
        }
        
        public var isCancelled: Bool { isCancellationRequested }
    }
}

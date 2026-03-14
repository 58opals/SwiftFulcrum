// FulcrumNetworkClient+Call.swift

import Foundation

extension FulcrumNetworkClient {
    enum Call {}
}

extension FulcrumNetworkClient.Call {
    struct Options: Sendable {
        public var timeout: Duration?
        public var token: FulcrumNetworkClient.Call.Token?
        
        init(timeout: Duration? = nil, token: FulcrumNetworkClient.Call.Token? = nil) {
            self.timeout = timeout
            self.token = token
        }
    }
    
    actor Token {
        private var handlers: [@Sendable () async -> Void] = .init()
        private var isCancellationRequested = false
        
        init() {}
        
        func register(_ handler: @escaping @Sendable () async -> Void) async {
            if isCancellationRequested {
                await handler()
            } else {
                handlers.append(handler)
            }
        }
        
        public func cancel() async {
            guard !isCancellationRequested else { return }
            
            isCancellationRequested = true
            let registeredHandlers = handlers
            handlers.removeAll(keepingCapacity: false)
            
            for handler in registeredHandlers {
                await handler()
            }
        }
        
        public var isCancelled: Bool { isCancellationRequested }
    }
}

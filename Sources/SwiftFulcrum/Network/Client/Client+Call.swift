// Client+Call.swift

import Foundation

extension Client {
    enum Call {}
}

extension Client.Call {
    struct Options: Sendable {
        public var timeout: Duration?
        public var token: Client.Call.Token?
        
        init(timeout: Duration? = nil, token: Client.Call.Token? = nil) {
            self.timeout = timeout
            self.token = token
        }
    }
    
    actor Token {
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

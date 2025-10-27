// Client+Call.swift

import Foundation

extension Client {
    public enum Call {}
}

extension Client.Call {
    public struct Options: Sendable {
        public var timeout: Duration?
        public var token: Client.Call.Token?
        
        public init(timeout: Duration? = nil, token: Client.Call.Token? = nil) {
            self.timeout = timeout
            self.token = token
        }
    }
    
    public actor Token {
        private var handler: (@Sendable () -> Void)?
        private var isCancellationRequested = false
        public init() {}
        
        func register(_ handler: @escaping @Sendable () -> Void) {
            if isCancellationRequested { handler() } else { self.handler = handler }
        }
        
        public func cancel() { isCancellationRequested = true; handler?() }
        public var isCancelled: Bool { isCancellationRequested }
    }
}

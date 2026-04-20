// FulcrumNetworkClient.Call+Token.swift

import Foundation

extension FulcrumNetworkClient.Call {
    actor Token {
        typealias RegistrationID = UUID

        private var handlers: [RegistrationID: @Sendable () async -> Void] = .init()
        private var isCancellationRequested = false

        init() {}

        @discardableResult
        func register(_ handler: @escaping @Sendable () async -> Void) async -> RegistrationID? {
            if isCancellationRequested {
                await handler()
                return nil
            } else {
                let registrationID = RegistrationID()
                handlers[registrationID] = handler
                return registrationID
            }
        }

        func unregister(_ registrationID: RegistrationID) {
            handlers.removeValue(forKey: registrationID)
        }

        public func cancel() async {
            guard !isCancellationRequested else { return }

            isCancellationRequested = true
            let registeredHandlers = handlers
            handlers.removeAll(keepingCapacity: false)

            for handler in registeredHandlers.values {
                await handler()
            }
        }

        public var isCancelled: Bool { isCancellationRequested }
    }
}

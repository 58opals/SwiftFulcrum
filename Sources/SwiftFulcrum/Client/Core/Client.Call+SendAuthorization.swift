// Client.Call+SendAuthorization.swift

extension SwiftFulcrum.Client.Call {
    /// Authorizes one outbound unary call at the final WebSocket handoff.
    ///
    /// The validator runs synchronously after connection preparation and actor waits.
    /// Capture the call's immutable authorization context and read current validity
    /// without suspension. Returning false prevents handing the message to URLSession.
    /// Subscription APIs reject options containing a send authorization.
    public struct SendAuthorization: Sendable {
        private let isAuthorized: @Sendable () -> Bool

        public init(isAuthorized: @escaping @Sendable () -> Bool) {
            self.isAuthorized = isAuthorized
        }

        func validate() throws {
            guard isAuthorized() else {
                throw SwiftFulcrum.Client.Error.client(.sendNotAuthorized)
            }
        }
    }
}

// SwiftFulcrum.API+Subscription.swift

extension SwiftFulcrum.API {
    public struct Subscription<Initial: Decodable & Sendable, Notification: Decodable & Sendable>: Sendable {
        let method: SwiftFulcrum.RPC.Method

        init(method: SwiftFulcrum.RPC.Method) {
            self.method = method
        }
    }
}

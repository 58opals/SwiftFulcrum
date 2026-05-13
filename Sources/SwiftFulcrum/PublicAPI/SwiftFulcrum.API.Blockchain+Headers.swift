// SwiftFulcrum.API.Blockchain+Headers.swift

extension SwiftFulcrum.API.Blockchain {
    public struct Headers: Sendable {
        public var tip: SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Headers.Tip> {
            .init(method: .blockchain(.headers(.getTip)))
        }

        public var subscribe: SwiftFulcrum.API.Subscription<
            SwiftFulcrum.Response.Blockchain.Headers.Subscribe,
            SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification
        > {
            .init(method: .blockchain(.headers(.subscribe)))
        }

        public var unsubscribe: SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Headers.Unsubscribe> {
            .init(method: .blockchain(.headers(.unsubscribe)))
        }
    }
}

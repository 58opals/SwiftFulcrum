// SwiftFulcrum.API.Blockchain.Transaction+DSProof.swift

extension SwiftFulcrum.API.Blockchain.Transaction {
    public struct DSProof: Sendable {
        public func lookup(
            transactionHash: String
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Transaction.DSProof.Lookup> {
            .init(method: .blockchain(.transaction(.dsProof(.get(transactionHash: transactionHash)))))
        }

        public var list: SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Transaction.DSProof.List> {
            .init(method: .blockchain(.transaction(.dsProof(.list))))
        }

        public func subscribe(
            transactionHash: String
        ) -> SwiftFulcrum.API.Subscription<
            SwiftFulcrum.Response.Blockchain.Transaction.DSProof.Subscribe,
            SwiftFulcrum.Response.Blockchain.Transaction.DSProof.SubscribeNotification
        > {
            .init(method: .blockchain(.transaction(.dsProof(.subscribe(transactionHash: transactionHash)))))
        }

        public func unsubscribe(
            transactionHash: String
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Transaction.DSProof.Unsubscribe> {
            .init(method: .blockchain(.transaction(.dsProof(.unsubscribe(transactionHash: transactionHash)))))
        }
    }
}

// SwiftFulcrum.API.Blockchain+Transaction.swift

extension SwiftFulcrum.API.Blockchain {
    public struct Transaction: Sendable {
        public var dsProof: DSProof { .init() }

        public func broadcast(
            rawTransaction: String
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Transaction.Broadcast> {
            .init(method: .blockchain(.transaction(.broadcast(rawTransaction: rawTransaction))))
        }

        public func raw(
            transactionHash: String
        ) -> SwiftFulcrum.API.Request<String> {
            .init(method: .blockchain(.transaction(.get(transactionHash: transactionHash, isVerbose: false))))
        }

        public func verbose(
            transactionHash: String
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Transaction.Verbose> {
            .init(method: .blockchain(.transaction(.get(transactionHash: transactionHash, isVerbose: true))))
        }

        public func confirmedBlockHash(
            transactionHash: String,
            shouldIncludeHeader: Bool
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Transaction.ConfirmedBlockHash> {
            .init(
                method: .blockchain(
                    .transaction(
                        .getConfirmedBlockHash(
                            transactionHash: transactionHash,
                            shouldIncludeHeader: shouldIncludeHeader
                        )
                    )
                )
            )
        }

        public func height(
            transactionHash: String
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Transaction.Height> {
            .init(method: .blockchain(.transaction(.getHeight(transactionHash: transactionHash))))
        }

        public func merkle(
            transactionHash: String,
            height: UInt
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Transaction.Merkle> {
            .init(method: .blockchain(.transaction(.getMerkle(transactionHash: transactionHash, height: height))))
        }

        public func idFromPos(
            blockHeight: UInt,
            transactionPosition: UInt,
            shouldIncludeMerkleProof: Bool
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Transaction.IDFromPos> {
            .init(
                method: .blockchain(
                    .transaction(
                        .idFromPos(
                            blockHeight: blockHeight,
                            transactionPosition: transactionPosition,
                            shouldIncludeMerkleProof: shouldIncludeMerkleProof
                        )
                    )
                )
            )
        }

        public func subscribe(
            transactionHash: String
        ) -> SwiftFulcrum.API.Subscription<
            SwiftFulcrum.Response.Blockchain.Transaction.Subscribe,
            SwiftFulcrum.Response.Blockchain.Transaction.SubscribeNotification
        > {
            .init(method: .blockchain(.transaction(.subscribe(transactionHash: transactionHash))))
        }

        public func unsubscribe(
            transactionHash: String
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Transaction.Unsubscribe> {
            .init(method: .blockchain(.transaction(.unsubscribe(transactionHash: transactionHash))))
        }
    }
}

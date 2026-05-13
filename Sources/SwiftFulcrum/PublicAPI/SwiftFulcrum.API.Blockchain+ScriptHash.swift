// SwiftFulcrum.API.Blockchain+ScriptHash.swift

extension SwiftFulcrum.API.Blockchain {
    public struct ScriptHash: Sendable {
        public func balance(
            scriptHash: String,
            tokenFilter: SwiftFulcrum.CashTokens.TokenFilter? = nil
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.ScriptHash.Balance> {
            .init(method: .blockchain(.scripthash(.getBalance(scripthash: scriptHash, tokenFilter: tokenFilter))))
        }

        public func firstUse(
            scriptHash: String
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.ScriptHash.FirstUse> {
            .init(method: .blockchain(.scripthash(.getFirstUse(scripthash: scriptHash))))
        }

        public func history(
            scriptHash: String,
            fromHeight: UInt? = nil,
            toHeight: UInt? = nil,
            shouldIncludeUnconfirmed: Bool = true
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.ScriptHash.History> {
            .init(
                method: .blockchain(
                    .scripthash(
                        .getHistory(
                            scripthash: scriptHash,
                            fromHeight: fromHeight,
                            toHeight: toHeight,
                            shouldIncludeUnconfirmed: shouldIncludeUnconfirmed
                        )
                    )
                )
            )
        }

        public func mempool(
            scriptHash: String
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.ScriptHash.Mempool> {
            .init(method: .blockchain(.scripthash(.getMempool(scripthash: scriptHash))))
        }

        public func listUnspent(
            scriptHash: String,
            tokenFilter: SwiftFulcrum.CashTokens.TokenFilter? = nil
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.ScriptHash.ListUnspent> {
            .init(method: .blockchain(.scripthash(.listUnspent(scripthash: scriptHash, tokenFilter: tokenFilter))))
        }

        public func subscribe(
            scriptHash: String
        ) -> SwiftFulcrum.API.Subscription<
            SwiftFulcrum.Response.Blockchain.ScriptHash.Subscribe,
            SwiftFulcrum.Response.Blockchain.ScriptHash.SubscribeNotification
        > {
            .init(method: .blockchain(.scripthash(.subscribe(scripthash: scriptHash))))
        }

        public func unsubscribe(
            scriptHash: String
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.ScriptHash.Unsubscribe> {
            .init(method: .blockchain(.scripthash(.unsubscribe(scripthash: scriptHash))))
        }
    }
}

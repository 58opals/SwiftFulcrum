// SwiftFulcrum.API.Blockchain+Address.swift

extension SwiftFulcrum.API.Blockchain {
    public struct Address: Sendable {
        public func balance(
            address: String,
            tokenFilter: SwiftFulcrum.CashTokens.TokenFilter? = nil
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Address.Balance> {
            .init(method: .blockchain(.address(.getBalance(address: address, tokenFilter: tokenFilter))))
        }

        public func firstUse(
            address: String
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Address.FirstUse> {
            .init(method: .blockchain(.address(.getFirstUse(address: address))))
        }

        public func history(
            address: String,
            fromHeight: UInt? = nil,
            toHeight: UInt? = nil,
            shouldIncludeUnconfirmed: Bool = true
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Address.History> {
            .init(
                method: .blockchain(
                    .address(
                        .getHistory(
                            address: address,
                            fromHeight: fromHeight,
                            toHeight: toHeight,
                            shouldIncludeUnconfirmed: shouldIncludeUnconfirmed
                        )
                    )
                )
            )
        }

        public func mempool(
            address: String
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Address.Mempool> {
            .init(method: .blockchain(.address(.getMempool(address: address))))
        }

        public func scriptHash(
            address: String
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Address.ScriptHash> {
            .init(method: .blockchain(.address(.getScriptHash(address: address))))
        }

        public func listUnspent(
            address: String,
            tokenFilter: SwiftFulcrum.CashTokens.TokenFilter? = nil
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Address.ListUnspent> {
            .init(method: .blockchain(.address(.listUnspent(address: address, tokenFilter: tokenFilter))))
        }

        public func subscribe(
            address: String
        ) -> SwiftFulcrum.API.Subscription<
            SwiftFulcrum.Response.Blockchain.Address.Subscribe,
            SwiftFulcrum.Response.Blockchain.Address.SubscribeNotification
        > {
            .init(method: .blockchain(.address(.subscribe(address: address))))
        }

        public func unsubscribe(
            address: String
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Address.Unsubscribe> {
            .init(method: .blockchain(.address(.unsubscribe(address: address))))
        }
    }
}

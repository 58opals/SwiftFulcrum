// SwiftFulcrum+API.swift

import Foundation

extension SwiftFulcrum {
    public enum API {}
}

extension SwiftFulcrum.API {
    public struct Request<ResponsePayload: Decodable & Sendable>: Sendable {
        let method: SwiftFulcrum.RPC.Method

        init(method: SwiftFulcrum.RPC.Method) {
            self.method = method
        }
    }

    public struct Subscription<Initial: Decodable & Sendable, Notification: Decodable & Sendable>: Sendable {
        let method: SwiftFulcrum.RPC.Method

        init(method: SwiftFulcrum.RPC.Method) {
            self.method = method
        }
    }
}

extension SwiftFulcrum.API {
    public static var server: Server { .init() }
    public static var blockchain: Blockchain { .init() }
    public static var mempool: Mempool { .init() }
}

extension SwiftFulcrum.API.Request {
    public static var server: SwiftFulcrum.API.Server { .init() }
    public static var blockchain: SwiftFulcrum.API.Blockchain { .init() }
    public static var mempool: SwiftFulcrum.API.Mempool { .init() }
}

extension SwiftFulcrum.API.Subscription {
    public static var server: SwiftFulcrum.API.Server { .init() }
    public static var blockchain: SwiftFulcrum.API.Blockchain { .init() }
    public static var mempool: SwiftFulcrum.API.Mempool { .init() }
}

extension SwiftFulcrum.API {
    public struct Server: Sendable {
        public var ping: Request<SwiftFulcrum.Response.Server.Ping> {
            .init(method: .server(.ping))
        }

        public func version(
            clientName: String,
            protocolNegotiation: SwiftFulcrum.Client.Configuration.ProtocolNegotiation.Argument
        ) -> Request<SwiftFulcrum.Response.Server.Version> {
            .init(method: .server(.version(clientName: clientName, protocolNegotiation: protocolNegotiation)))
        }

        public var features: Request<SwiftFulcrum.Response.Server.Features> {
            .init(method: .server(.features))
        }
    }

    public struct Mempool: Sendable {
        public var getInfo: Request<SwiftFulcrum.Response.Mempool.GetInfo> {
            .init(method: .mempool(.getInfo))
        }

        public var getFeeHistogram: Request<SwiftFulcrum.Response.Mempool.GetFeeHistogram> {
            .init(method: .mempool(.getFeeHistogram))
        }
    }
}

extension SwiftFulcrum.API {
    public struct Blockchain: Sendable {
        public var scriptHash: ScriptHash { .init() }
        public var address: Address { .init() }
        public var block: Block { .init() }
        public var header: Header { .init() }
        public var headers: Headers { .init() }
        public var transaction: Transaction { .init() }
        public var utxo: UTXO { .init() }

        public func estimateFee(numberOfBlocks: Int) -> Request<SwiftFulcrum.Response.Blockchain.EstimateFee> {
            .init(method: .blockchain(.estimateFee(numberOfBlocks: numberOfBlocks)))
        }

        public var relayFee: Request<SwiftFulcrum.Response.Blockchain.RelayFee> {
            .init(method: .blockchain(.relayFee))
        }
    }
}

extension SwiftFulcrum.API.Blockchain {
    public struct ScriptHash: Sendable {
        public func getBalance(
            scriptHash: String,
            tokenFilter: SwiftFulcrum.CashTokens.TokenFilter? = nil
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.ScriptHash.GetBalance> {
            .init(method: .blockchain(.scripthash(.getBalance(scripthash: scriptHash, tokenFilter: tokenFilter))))
        }

        public func getFirstUse(
            scriptHash: String
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.ScriptHash.GetFirstUse> {
            .init(method: .blockchain(.scripthash(.getFirstUse(scripthash: scriptHash))))
        }

        public func getHistory(
            scriptHash: String,
            fromHeight: UInt? = nil,
            toHeight: UInt? = nil,
            shouldIncludeUnconfirmed: Bool = true
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.ScriptHash.GetHistory> {
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

        public func getMempool(
            scriptHash: String
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.ScriptHash.GetMempool> {
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

    public struct Address: Sendable {
        public func getBalance(
            address: String,
            tokenFilter: SwiftFulcrum.CashTokens.TokenFilter? = nil
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Address.GetBalance> {
            .init(method: .blockchain(.address(.getBalance(address: address, tokenFilter: tokenFilter))))
        }

        public func getFirstUse(
            address: String
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Address.GetFirstUse> {
            .init(method: .blockchain(.address(.getFirstUse(address: address))))
        }

        public func getHistory(
            address: String,
            fromHeight: UInt? = nil,
            toHeight: UInt? = nil,
            shouldIncludeUnconfirmed: Bool = true
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Address.GetHistory> {
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

        public func getMempool(
            address: String
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Address.GetMempool> {
            .init(method: .blockchain(.address(.getMempool(address: address))))
        }

        public func getScriptHash(
            address: String
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Address.GetScriptHash> {
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

extension SwiftFulcrum.API.Blockchain {
    public struct Block: Sendable {
        public func header(
            height: UInt,
            checkpointHeight: UInt? = nil
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Block.Header> {
            .init(method: .blockchain(.block(.header(height: height, checkpointHeight: checkpointHeight))))
        }

        public func headers(
            startHeight: UInt,
            count: UInt,
            checkpointHeight: UInt? = nil
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Block.Headers> {
            .init(
                method: .blockchain(
                    .block(.headers(startHeight: startHeight, count: count, checkpointHeight: checkpointHeight))
                )
            )
        }
    }

    public struct Header: Sendable {
        public func get(
            blockHash: String
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Header.Get> {
            .init(method: .blockchain(.header(.get(blockHash: blockHash))))
        }
    }

    public struct Headers: Sendable {
        public var getTip: SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Headers.GetTip> {
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

    public struct UTXO: Sendable {
        public func getInfo(
            transactionHash: String,
            outputIndex: UInt
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.UTXO.GetInfo> {
            .init(method: .blockchain(.utxo(.getInfo(transactionHash: transactionHash, outputIndex: outputIndex))))
        }
    }
}

extension SwiftFulcrum.API.Blockchain {
    public struct Transaction: Sendable {
        public var dsProof: DSProof { .init() }

        public func broadcast(
            rawTransaction: String
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Transaction.Broadcast> {
            .init(method: .blockchain(.transaction(.broadcast(rawTransaction: rawTransaction))))
        }

        public func get(
            transactionHash: String
        ) -> SwiftFulcrum.API.Request<String> {
            .init(method: .blockchain(.transaction(.get(transactionHash: transactionHash, isVerbose: false))))
        }

        public func getVerbose(
            transactionHash: String
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Transaction.Get> {
            .init(method: .blockchain(.transaction(.get(transactionHash: transactionHash, isVerbose: true))))
        }

        public func getConfirmedBlockHash(
            transactionHash: String,
            shouldIncludeHeader: Bool
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Transaction.GetConfirmedBlockHash> {
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

        public func getHeight(
            transactionHash: String
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Transaction.GetHeight> {
            .init(method: .blockchain(.transaction(.getHeight(transactionHash: transactionHash))))
        }

        public func getMerkle(
            transactionHash: String,
            height: UInt
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Transaction.GetMerkle> {
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

extension SwiftFulcrum.API.Blockchain.Transaction {
    public struct DSProof: Sendable {
        public func get(
            transactionHash: String
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Transaction.DSProof.Get> {
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

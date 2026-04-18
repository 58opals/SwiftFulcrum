// Response.Result.Blockchain+ScriptHash.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain {
    public struct ScriptHash {
        public struct GetBalance: Decodable, Sendable {
            public let confirmed: UInt64
            public let unconfirmed: Int64

            public init(from decoder: Decoder) throws {
                let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.GetBalance(from: decoder)
                self.confirmed = payloadModel.confirmed
                self.unconfirmed = payloadModel.unconfirmed
            }
        }
        
        public struct GetFirstUse: Decodable, Sendable {
            public let blockHash: String?
            public let height: UInt?
            public let transactionHash: String?
            public var isFound: Bool { blockHash != nil }

            init(blockHash: String?, height: UInt?, transactionHash: String?) {
                self.blockHash = blockHash
                self.height = height
                self.transactionHash = transactionHash
            }

            public init(from decoder: Decoder) throws {
                let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.GetFirstUse(from: decoder)
                self.blockHash = payloadModel.block_hash
                self.height = payloadModel.height
                self.transactionHash = payloadModel.tx_hash
            }
        }
        
        public struct GetHistory: Decodable, Sendable {
            public let transactions: [Transaction]

            public struct Transaction: Decodable, Sendable {
                public let height: Int
                public let transactionHash: String
                public let fee: UInt?

                init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.GetHistoryItem) {
                    self.height = payloadModel.height
                    self.transactionHash = payloadModel.tx_hash
                    self.fee = payloadModel.fee
                }
            }

            public init(from decoder: Decoder) throws {
                let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.GetHistory(from: decoder)
                self.transactions = payloadModel.map(Transaction.init(from:))
            }
        }
        
        public struct GetMempool: Decodable, Sendable {
            public let transactions: [Transaction]

            public struct Transaction: Decodable, Sendable {
                public let height: Int
                public let transactionHash: String
                public let fee: UInt?

                init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.GetMempoolItem) {
                    self.height = payloadModel.height
                    self.transactionHash = payloadModel.tx_hash
                    self.fee = payloadModel.fee
                }
            }

            public init(from decoder: Decoder) throws {
                let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.GetMempool(from: decoder)
                self.transactions = payloadModel.map(Transaction.init(from:))
            }
        }
        
        public struct ListUnspent: Decodable, Sendable {
            public let items: [Item]

            public struct Item: Decodable, Sendable {
                public let height: UInt
                public let tokenData: SwiftFulcrum.RPC.Method.Blockchain.CashTokens.JSON?
                public let transactionHash: String
                public let transactionPosition: UInt
                public let value: UInt64

                init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.ListUnspentItem) {
                    self.height = payloadModel.height
                    self.tokenData = payloadModel.token_data
                    self.transactionHash = payloadModel.tx_hash
                    self.transactionPosition = payloadModel.tx_pos
                    self.value = payloadModel.value
                }
            }

            public init(from decoder: Decoder) throws {
                let payloadModel = try [SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.ListUnspentItem](from: decoder)
                self.items = payloadModel.map(Item.init(from:))
            }
        }
        
        public struct Subscribe: Decodable, Sendable {
            public let status: String?

            init(status: String?) {
                self.status = status
            }

            public init(from decoder: Decoder) throws {
                let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.Subscribe(from: decoder)

                switch payloadModel {
                case .status(let statusString):
                    self.status = statusString
                case .scripthashAndStatus(let pair):
                    throw ResponseResultDecodeError.unexpectedFormat("Expected a status string; got scripthash and status array for ScriptHash.Subscribe: \(pair.description)")
                }
            }
        }
        
        public struct SubscribeNotification: Decodable, Sendable {
            public let subscriptionIdentifier: String
            public let status: String?

            public init(from decoder: Decoder) throws {
                let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.ScriptHash.Subscribe(from: decoder)
                switch payloadModel {
                case .scripthashAndStatus(let pair):
                    guard (1 ... 2).contains(pair.count) else {
                        throw ResponseResultDecodeError.unexpectedFormat(
                            "Expected scripthash notification payload to contain [scripthash] or [scripthash, status]; got \(pair.description)"
                        )
                    }
                    guard let first = pair.first, let scripthash = first else { throw ResponseResultDecodeError.missingField("subscriptionIdentifier") }
                    self.subscriptionIdentifier = scripthash
                    self.status = (pair.count > 1) ? pair[1] : nil
                case .status(let statusString):
                    throw ResponseResultDecodeError.unexpectedFormat("Expected scripthash and status pair; got single status: \(statusString)")
                }
            }
        }
        
        public struct Unsubscribe: Decodable, Sendable {
            public let isSuccess: Bool

            public init(from decoder: Decoder) throws {
                self.isSuccess = try Bool(from: decoder)
            }
        }
    }
}

extension SwiftFulcrum.RPC.Response.Result.Blockchain.ScriptHash.GetFirstUse: JSONRPCResponseDecodeModel.NilValueModel {
    static var nilValue: Self { .init(blockHash: nil, height: nil, transactionHash: nil) }
}

extension SwiftFulcrum.RPC.Response.Result.Blockchain.ScriptHash.Subscribe: JSONRPCResponseDecodeModel.NilValueModel {
    static var nilValue: Self { .init(status: nil) }
}

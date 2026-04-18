// Response.Result.Blockchain+Address.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain {
    public struct Address {
        public struct GetBalance: Decodable, Sendable {
            public let confirmed: UInt64
            public let unconfirmed: Int64

            public init(from decoder: Decoder) throws {
                let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.GetBalance(from: decoder)
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
                let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.GetFirstUse(from: decoder)
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

                init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.GetHistoryItem) {
                    self.height = payloadModel.height
                    self.transactionHash = payloadModel.tx_hash
                    self.fee = payloadModel.fee
                }
            }

            public init(from decoder: Decoder) throws {
                let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.GetHistory(from: decoder)
                self.transactions = payloadModel.map(Transaction.init(from:))
            }
        }
        
        public struct GetMempool: Decodable, Sendable {
            public let transactions: [Transaction]

            public struct Transaction: Decodable, Sendable {
                public let height: Int
                public let transactionHash: String
                public let fee: UInt?

                init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.GetMempoolItem) {
                    self.height = payloadModel.height
                    self.transactionHash = payloadModel.tx_hash
                    self.fee = payloadModel.fee
                }
            }

            public init(from decoder: Decoder) throws {
                let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.GetMempool(from: decoder)
                self.transactions = payloadModel.map(Transaction.init(from:))
            }
        }
        
        public struct GetScriptHash: Decodable, Sendable {
            public let scriptHash: String

            public init(from decoder: Decoder) throws {
                self.scriptHash = try String(from: decoder)
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

                init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.ListUnspentItem) {
                    self.height = payloadModel.height
                    self.tokenData = payloadModel.token_data
                    self.transactionHash = payloadModel.tx_hash
                    self.transactionPosition = payloadModel.tx_pos
                    self.value = payloadModel.value
                }
            }

            public init(from decoder: Decoder) throws {
                let payloadModel = try [SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.ListUnspentItem](from: decoder)
                self.items = payloadModel.map(Item.init(from:))
            }
        }
        
        public struct Subscribe: Decodable, Sendable {
            public let status: String?

            init(status: String?) {
                self.status = status
            }

            public init(from decoder: Decoder) throws {
                let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.Subscribe(from: decoder)
                switch payloadModel {
                case .status(let statusString):
                    self.status = statusString
                case .addressAndStatus(let pair):
                    throw ResponseResultDecodeError.unexpectedFormat("Expected a status string; got address and status array for Address.Subscribe: \(pair.description)")
                }
            }
        }
        
        public struct SubscribeNotification: Decodable, Sendable {
            public let subscriptionIdentifier: String
            public let status: String?

            public init(from decoder: Decoder) throws {
                let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Address.Subscribe(from: decoder)
                switch payloadModel {
                case .addressAndStatus(let pair):
                    guard (1 ... 2).contains(pair.count) else {
                        throw ResponseResultDecodeError.unexpectedFormat(
                            "Expected address notification payload to contain [address] or [address, status]; got \(pair.description)"
                        )
                    }
                    guard let first = pair.first, let address = first else { throw ResponseResultDecodeError.missingField("subscriptionIdentifier") }
                    self.subscriptionIdentifier = address
                    self.status = (pair.count > 1) ? pair[1] : nil
                case .status(let statusString):
                    throw ResponseResultDecodeError.unexpectedFormat("Expected address and status pair; got single status: \(statusString)")
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

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Address.GetFirstUse: JSONRPCResponseDecodeModel.NilValueModel {
    static var nilValue: Self { .init(blockHash: nil, height: nil, transactionHash: nil) }
}

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Address.Subscribe: JSONRPCResponseDecodeModel.NilValueModel {
    static var nilValue: Self { .init(status: nil) }
}

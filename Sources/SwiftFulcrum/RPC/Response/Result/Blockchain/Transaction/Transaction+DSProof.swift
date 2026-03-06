// Transaction+DSProof.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction {
    public struct DSProof {
        public struct Get: SwiftFulcrum.RPC.JSONRPCResponseAdapter {
            public let dsProofID: String
            public let transactionID: String
            public let hex: String
            public let outpoint: Outpoint
            public let descendants: [String]

            public struct Outpoint: Decodable, Sendable {
                public let transactionID: String
                public let outputIndex: UInt

                init(from json: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Get.Outpoint) {
                    self.transactionID = json.txid
                    self.outputIndex = json.vout
                }
            }

            public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Get

            public init(fromRPC jsonrpc: JSONRPC) {
                self.dsProofID = jsonrpc.dspid
                self.transactionID = jsonrpc.txid
                self.hex = jsonrpc.hex
                self.outpoint = Outpoint(from: jsonrpc.outpoint)
                self.descendants = jsonrpc.descendants
            }
        }

        public struct List: SwiftFulcrum.RPC.JSONRPCResponseAdapter {
            public let transactionHashes: [String]

            public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof.List

            public init(fromRPC jsonrpc: JSONRPC) {
                self.transactionHashes = jsonrpc
            }
        }

        public struct Subscribe: SwiftFulcrum.RPC.JSONRPCResponseAdapter {
            public let proof: Get?

            public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Subscribe

            public init(fromRPC jsonrpc: JSONRPC) throws {
                switch jsonrpc {
                case .dsProof(let proof):
                    self.proof = proof.map { Get(fromRPC: $0) }
                case .transactionHashAndDSProof(let pairs):
                    throw SwiftFulcrum.RPC.Response.Result.Error.unexpectedFormat(
                        "Expected DSProof or nil for DSProof.Subscribe initial response; got [txHash, DSProof]: \(pairs)"
                    )
                }
            }
        }

        public struct SubscribeNotification: SwiftFulcrum.RPC.JSONRPCResponseAdapter {
            public let subscriptionIdentifier: String
            public let transactionHash: String
            public let proof: Get?

            public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Subscribe

            public init(fromRPC jsonrpc: JSONRPC) throws {
                switch jsonrpc {
                case .transactionHashAndDSProof(let pairs):
                    var hashValue: String?
                    var rawProofValue: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Get?

                    for pair in pairs {
                        switch pair {
                        case .transactionHash(let hash):
                            guard hashValue == nil else {
                                throw SwiftFulcrum.RPC.Response.Result.Error.unexpectedFormat("Duplicate txHash in DSProof notification payload")
                            }
                            hashValue = hash
                        case .dsProof(let proof):
                            guard rawProofValue == nil else {
                                throw SwiftFulcrum.RPC.Response.Result.Error.unexpectedFormat("Duplicate dsProof in DSProof notification payload")
                            }
                            rawProofValue = proof
                        }
                    }

                    guard let hash = hashValue else {
                        throw SwiftFulcrum.RPC.Response.Result.Error.missingField("transactionHash")
                    }

                    self.subscriptionIdentifier = hash
                    self.transactionHash = hash
                    self.proof = rawProofValue.map { Get(fromRPC: $0) }
                case .dsProof(let proof):
                    guard let rawProof = proof else {
                        throw SwiftFulcrum.RPC.Response.Result.Error.unexpectedFormat(
                            "Nil DSProof in notification without accompanying transaction hash"
                        )
                    }
                    let hash = rawProof.txid
                    self.subscriptionIdentifier = hash
                    self.transactionHash = hash
                    self.proof = Get(fromRPC: rawProof)
                }
            }
        }

        public struct Unsubscribe: SwiftFulcrum.RPC.JSONRPCResponseAdapter {
            public let isSuccess: Bool

            public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Unsubscribe

            public init(fromRPC jsonrpc: JSONRPC) {
                self.isSuccess = jsonrpc
            }
        }
    }
}

import Foundation

extension SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Transaction {
    public struct DSProof {
        public struct Get: SwiftFulcrum.RPC.ResponseProtocol {
            public let dsProofID: String
            public let transactionID: String
            public let hex: String
            public let outpoint: Outpoint
            public let descendants: [String]

            public struct Outpoint: Decodable, Sendable {
                public let transactionID: String
                public let outputIndex: UInt

                init(from json: SwiftFulcrum.RPC.Response.JSONRPCModel.Result.Blockchain.Transaction.DSProof.Get.Outpoint) {
                    self.transactionID = json.txid
                    self.outputIndex = json.vout
                }
            }

            public typealias JSONRPCModel = SwiftFulcrum.RPC.Response.JSONRPCModel.Result.Blockchain.Transaction.DSProof.Get

            public init(fromRPC jsonrpc: JSONRPCModel) {
                self.dsProofID = jsonrpc.dspid
                self.transactionID = jsonrpc.txid
                self.hex = jsonrpc.hex
                self.outpoint = Outpoint(from: jsonrpc.outpoint)
                self.descendants = jsonrpc.descendants
            }
        }

        public struct List: SwiftFulcrum.RPC.ResponseProtocol {
            public let transactionHashes: [String]

            public typealias JSONRPCModel = SwiftFulcrum.RPC.Response.JSONRPCModel.Result.Blockchain.Transaction.DSProof.List

            public init(fromRPC jsonrpc: JSONRPCModel) {
                self.transactionHashes = jsonrpc
            }
        }

        public struct Subscribe: SwiftFulcrum.RPC.ResponseProtocol {
            public let proof: Get?

            public typealias JSONRPCModel = SwiftFulcrum.RPC.Response.JSONRPCModel.Result.Blockchain.Transaction.DSProof.Subscribe

            public init(fromRPC jsonrpc: JSONRPCModel) throws {
                switch jsonrpc {
                case .dsProof(let proof):
                    self.proof = proof.map { Get(fromRPC: $0) }
                case .transactionHashAndDSProof(let pairs):
                    throw SwiftFulcrum.RPC.Response.ResultModel.Error.unexpectedFormat(
                        "Expected DSProof or nil for DSProof.Subscribe initial response; got [txHash, DSProof]: \(pairs)"
                    )
                }
            }
        }

        public struct SubscribeNotification: SwiftFulcrum.RPC.ResponseProtocol {
            public let subscriptionIdentifier: String
            public let transactionHash: String
            public let proof: Get?

            public typealias JSONRPCModel = SwiftFulcrum.RPC.Response.JSONRPCModel.Result.Blockchain.Transaction.DSProof.Subscribe

            public init(fromRPC jsonrpc: JSONRPCModel) throws {
                switch jsonrpc {
                case .transactionHashAndDSProof(let pairs):
                    var hashValue: String?
                    var rawProofValue: SwiftFulcrum.RPC.Response.JSONRPCModel.Result.Blockchain.Transaction.DSProof.Get?

                    for pair in pairs {
                        switch pair {
                        case .transactionHash(let hash):
                            guard hashValue == nil else {
                                throw SwiftFulcrum.RPC.Response.ResultModel.Error.unexpectedFormat("Duplicate txHash in DSProof notification payload")
                            }
                            hashValue = hash
                        case .dsProof(let proof):
                            guard rawProofValue == nil else {
                                throw SwiftFulcrum.RPC.Response.ResultModel.Error.unexpectedFormat("Duplicate dsProof in DSProof notification payload")
                            }
                            rawProofValue = proof
                        }
                    }

                    guard let hash = hashValue else {
                        throw SwiftFulcrum.RPC.Response.ResultModel.Error.missingField("transactionHash")
                    }

                    self.subscriptionIdentifier = hash
                    self.transactionHash = hash
                    self.proof = rawProofValue.map { Get(fromRPC: $0) }
                case .dsProof(let proof):
                    guard let rawProof = proof else {
                        throw SwiftFulcrum.RPC.Response.ResultModel.Error.unexpectedFormat(
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

        public struct Unsubscribe: SwiftFulcrum.RPC.ResponseProtocol {
            public let isSuccess: Bool

            public typealias JSONRPCModel = SwiftFulcrum.RPC.Response.JSONRPCModel.Result.Blockchain.Transaction.DSProof.Unsubscribe

            public init(fromRPC jsonrpc: JSONRPCModel) {
                self.isSuccess = jsonrpc
            }
        }
    }
}

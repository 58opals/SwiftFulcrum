import Foundation

extension FulcrumResponse.ResultModel.BlockchainModel.TransactionModel {
    public struct DSProofModel {
        public struct GetModel: JSONRPCResponse {
            public let dsProofID: String
            public let transactionID: String
            public let hex: String
            public let outpoint: OutpointModel
            public let descendants: [String]

            public struct OutpointModel: Decodable, Sendable {
                public let transactionID: String
                public let outputIndex: UInt

                init(from json: FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.DSProofModel.GetModel.OutpointModel) {
                    self.transactionID = json.txid
                    self.outputIndex = json.vout
                }
            }

            public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.DSProofModel.GetModel

            public init(fromRPC jsonrpc: JSONRPCModel) {
                self.dsProofID = jsonrpc.dspid
                self.transactionID = jsonrpc.txid
                self.hex = jsonrpc.hex
                self.outpoint = OutpointModel(from: jsonrpc.outpoint)
                self.descendants = jsonrpc.descendants
            }
        }

        public struct ListModel: JSONRPCResponse {
            public let transactionHashes: [String]

            public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.DSProofModel.ListModel

            public init(fromRPC jsonrpc: JSONRPCModel) {
                self.transactionHashes = jsonrpc
            }
        }

        public struct SubscribeModel: JSONRPCResponse {
            public let proof: GetModel?

            public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.DSProofModel.SubscribeModel

            public init(fromRPC jsonrpc: JSONRPCModel) throws {
                switch jsonrpc {
                case .dsProof(let proof):
                    self.proof = proof.map { GetModel(fromRPC: $0) }
                case .transactionHashAndDSProof(let pairs):
                    throw FulcrumResponse.ResultModel.Error.unexpectedFormat(
                        "Expected DSProofModel or nil for DSProofModel.SubscribeModel initial response; got [txHash, DSProofModel]: \(pairs)"
                    )
                }
            }
        }

        public struct SubscribeNotificationModel: JSONRPCResponse {
            public let subscriptionIdentifier: String
            public let transactionHash: String
            public let proof: GetModel?

            public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.DSProofModel.SubscribeModel

            public init(fromRPC jsonrpc: JSONRPCModel) throws {
                switch jsonrpc {
                case .transactionHashAndDSProof(let pairs):
                    var hashValue: String?
                    var rawProofValue: FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.DSProofModel.GetModel?

                    for pair in pairs {
                        switch pair {
                        case .transactionHash(let hash):
                            guard hashValue == nil else {
                                throw FulcrumResponse.ResultModel.Error.unexpectedFormat("Duplicate txHash in DSProofModel notification payload")
                            }
                            hashValue = hash
                        case .dsProof(let proof):
                            guard rawProofValue == nil else {
                                throw FulcrumResponse.ResultModel.Error.unexpectedFormat("Duplicate dsProof in DSProofModel notification payload")
                            }
                            rawProofValue = proof
                        }
                    }

                    guard let hash = hashValue else {
                        throw FulcrumResponse.ResultModel.Error.missingField("transactionHash")
                    }

                    self.subscriptionIdentifier = hash
                    self.transactionHash = hash
                    self.proof = rawProofValue.map { GetModel(fromRPC: $0) }
                case .dsProof(let proof):
                    guard let rawProof = proof else {
                        throw FulcrumResponse.ResultModel.Error.unexpectedFormat(
                            "Nil DSProofModel in notification without accompanying transaction hash"
                        )
                    }
                    let hash = rawProof.txid
                    self.subscriptionIdentifier = hash
                    self.transactionHash = hash
                    self.proof = GetModel(fromRPC: rawProof)
                }
            }
        }

        public struct UnsubscribeModel: JSONRPCResponse {
            public let isSuccess: Bool

            public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.TransactionModel.DSProofModel.UnsubscribeModel

            public init(fromRPC jsonrpc: JSONRPCModel) {
                self.isSuccess = jsonrpc
            }
        }
    }
}

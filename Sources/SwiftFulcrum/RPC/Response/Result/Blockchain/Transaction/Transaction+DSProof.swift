// Transaction+DSProof.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction {
    public struct DSProof {
        public struct Get: Decodable, Sendable {
            public let dsProofID: String
            public let transactionID: String
            public let hex: String
            public let outpoint: Outpoint
            public let descendants: [String]

            public struct Outpoint: Decodable, Sendable {
                public let transactionID: String
                public let outputIndex: UInt

                init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Get.Outpoint) {
                    self.transactionID = payloadModel.txid
                    self.outputIndex = payloadModel.vout
                }
            }

            public init(from decoder: Decoder) throws {
                let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Get(from: decoder)
                self.dsProofID = payloadModel.dspid
                self.transactionID = payloadModel.txid
                self.hex = payloadModel.hex
                self.outpoint = Outpoint(from: payloadModel.outpoint)
                self.descendants = payloadModel.descendants
            }
        }

        public struct List: Decodable, Sendable {
            public let transactionHashes: [String]

            public init(from decoder: Decoder) throws {
                self.transactionHashes = try [String](from: decoder)
            }
        }

        public struct Subscribe: Decodable, Sendable {
            public let proof: Get?

            public init(from decoder: Decoder) throws {
                let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Subscribe(from: decoder)
                switch payloadModel {
                case .dsProof(let proof):
                    self.proof = proof.map(Get.init(from:))
                case .transactionHashAndDSProof(let pairs):
                    throw ResponseResultDecodeError.unexpectedFormat(
                        "Expected DSProof or nil for DSProof.Subscribe initial response; got [txHash, DSProof]: \(pairs)"
                    )
                }
            }
        }

        public struct SubscribeNotification: Decodable, Sendable {
            public let subscriptionIdentifier: String
            public let transactionHash: String
            public let proof: Get?

            public init(from decoder: Decoder) throws {
                let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Subscribe(from: decoder)
                switch payloadModel {
                case .transactionHashAndDSProof(let pairs):
                    var hashValue: String?
                    var proofValue: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Get?

                    for pair in pairs {
                        switch pair {
                        case .transactionHash(let hash):
                            guard hashValue == nil else {
                                throw ResponseResultDecodeError.unexpectedFormat("Duplicate txHash in DSProof notification payload")
                            }
                            hashValue = hash
                        case .dsProof(let proof):
                            guard proofValue == nil else {
                                throw ResponseResultDecodeError.unexpectedFormat("Duplicate dsProof in DSProof notification payload")
                            }
                            proofValue = proof
                        }
                    }

                    guard let hash = hashValue else {
                        throw ResponseResultDecodeError.missingField("transactionHash")
                    }

                    self.subscriptionIdentifier = hash
                    self.transactionHash = hash
                    self.proof = proofValue.map(Get.init(from:))
                case .dsProof(let proof):
                    guard let rawProof = proof else {
                        throw ResponseResultDecodeError.unexpectedFormat(
                            "Nil DSProof in notification without accompanying transaction hash"
                        )
                    }
                    let hash = rawProof.txid
                    self.subscriptionIdentifier = hash
                    self.transactionHash = hash
                    self.proof = Get(from: rawProof)
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

private extension SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction.DSProof.Get {
    init(from payloadModel: SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Get) {
        self.dsProofID = payloadModel.dspid
        self.transactionID = payloadModel.txid
        self.hex = payloadModel.hex
        self.outpoint = Outpoint(from: payloadModel.outpoint)
        self.descendants = payloadModel.descendants
    }
}

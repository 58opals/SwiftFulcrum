// Method~TransactionRequest.swift

import Foundation

extension SwiftFulcrum.RPC.Method {
    func createTransactionRequest(_ transaction: Blockchain.Transaction, uuid: UUID) -> FulcrumRequest {
        switch transaction {
        case .broadcast(let rawTransaction):
            struct ParametersModel: Encodable {
                let rawTransaction: String
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(rawTransaction)
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(rawTransaction: rawTransaction))

        case .get(let transactionHash, let isVerbose):
            struct ParametersModel: Encodable {
                let transactionHash: String
                let isVerbose: Bool
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(transactionHash)
                    try container.encode(isVerbose)
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(transactionHash: transactionHash,
                                              isVerbose: isVerbose))

        case .getConfirmedBlockHash(let transactionHash, let shouldIncludeHeader):
            struct ParametersModel: Encodable {
                let transactionHash: String
                let shouldIncludeHeader: Bool
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(transactionHash)
                    try container.encode(shouldIncludeHeader)
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(transactionHash: transactionHash,
                                              shouldIncludeHeader: shouldIncludeHeader))

        case .getHeight(let transactionHash):
            struct ParametersModel: Encodable {
                let transactionHash: String
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(transactionHash)
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(transactionHash: transactionHash))

        case .getMerkle(let transactionHash):
            struct ParametersModel: Encodable {
                let transactionHash: String
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(transactionHash)
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(transactionHash: transactionHash))

        case .idFromPos(let blockHeight, let transactionPosition, let shouldIncludeMerkleProof):
            struct ParametersModel: Encodable {
                let blockHeight: UInt
                let transactionPosition: UInt
                let shouldIncludeMerkleProof: Bool
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(blockHeight)
                    try container.encode(transactionPosition)
                    try container.encode(shouldIncludeMerkleProof)
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(blockHeight: blockHeight,
                                              transactionPosition: transactionPosition,
                                              shouldIncludeMerkleProof: shouldIncludeMerkleProof))

        case .subscribe(let transactionHash):
            struct ParametersModel: Encodable {
                let transactionHash: String
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(transactionHash)
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(transactionHash: transactionHash))

        case .unsubscribe(let transactionHash):
            struct ParametersModel: Encodable {
                let transactionHash: String
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(transactionHash)
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(transactionHash: transactionHash))

        case .dsProof(let dSProof):
            return createDSProofRequest(dSProof, uuid: uuid)
        }
    }
}

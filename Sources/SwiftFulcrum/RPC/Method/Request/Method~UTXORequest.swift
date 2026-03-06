// Method~UTXORequest.swift

import Foundation

extension SwiftFulcrum.RPC.Method {
    func createUTXORequest(_ utxo: Blockchain.UTXO, uuid: UUID) -> FulcrumRequest {
        switch utxo {
        case .getInfo(let transactionHash, let outputIndex):
            struct ParametersModel: Encodable {
                let transactionHash: String
                let outputIndex: UInt16
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(transactionHash)
                    try container.encode(outputIndex)
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(transactionHash: transactionHash,
                                              outputIndex: outputIndex))
        }
    }
}

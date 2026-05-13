// Method~UTXORequest.swift

import Foundation

extension SwiftFulcrum.RPC.Method {
    func createUTXORequest(_ utxo: Blockchain.UTXO, uuid: UUID) -> FulcrumRequest {
        switch utxo {
        case .getInfo(let transactionHash, let outputIndex):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.Pair(
                                      first: transactionHash,
                                      second: outputIndex
                                  ))
        }
    }
}

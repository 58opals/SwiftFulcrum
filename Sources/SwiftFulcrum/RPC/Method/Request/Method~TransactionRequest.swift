// Method~TransactionRequest.swift

import Foundation

extension SwiftFulcrum.RPC.Method {
    func createTransactionRequest(_ transaction: Blockchain.Transaction, uuid: UUID) -> FulcrumRequest {
        switch transaction {
        case .broadcast(let rawTransaction):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.SingleValueModel(value: rawTransaction))

        case .get(let transactionHash, let isVerbose):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.PairModel(
                                      first: transactionHash,
                                      second: isVerbose
                                  ))

        case .getConfirmedBlockHash(let transactionHash, let shouldIncludeHeader):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.PairModel(
                                      first: transactionHash,
                                      second: shouldIncludeHeader
                                  ))

        case .getHeight(let transactionHash):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.SingleValueModel(value: transactionHash))

        case .getMerkle(let transactionHash):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.SingleValueModel(value: transactionHash))

        case .idFromPos(let blockHeight, let transactionPosition, let shouldIncludeMerkleProof):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.TripleModel(
                                      first: blockHeight,
                                      second: transactionPosition,
                                      third: shouldIncludeMerkleProof
                                  ))

        case .subscribe(let transactionHash):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.SingleValueModel(value: transactionHash))

        case .unsubscribe(let transactionHash):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.SingleValueModel(value: transactionHash))

        case .dsProof(let dSProof):
            return createDSProofRequest(dSProof, uuid: uuid)
        }
    }
}

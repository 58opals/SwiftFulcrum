// Method~DSProofRequest.swift

import Foundation

extension SwiftFulcrum.RPC.Method {
    func createDSProofRequest(
        _ dSProof: Blockchain.Transaction.DSProof,
        uuid: UUID
    ) -> FulcrumRequest {
        switch dSProof {
        case .get(let transactionHash):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.SingleValueModel(value: transactionHash))

        case .list:
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.EmptyModel())

        case .subscribe(let transactionHash):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.SingleValueModel(value: transactionHash))

        case .unsubscribe(let transactionHash):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.SingleValueModel(value: transactionHash))
        }
    }
}

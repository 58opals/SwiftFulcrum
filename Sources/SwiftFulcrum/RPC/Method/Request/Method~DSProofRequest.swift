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
                                  params: RPCRequestParametersModel.SingleValue(value: transactionHash))

        case .list:
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.Empty())

        case .subscribe(let transactionHash):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.SingleValue(value: transactionHash))

        case .unsubscribe(let transactionHash):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.SingleValue(value: transactionHash))
        }
    }
}

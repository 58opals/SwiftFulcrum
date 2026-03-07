// Method~MempoolRequest.swift

import Foundation

extension SwiftFulcrum.RPC.Method {
    func createMempoolRequest(_ mempool: Mempool, uuid: UUID) -> FulcrumRequest {
        switch mempool {
        case .getInfo:
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.EmptyModel())

        case .getFeeHistogram:
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.EmptyModel())
        }
    }
}

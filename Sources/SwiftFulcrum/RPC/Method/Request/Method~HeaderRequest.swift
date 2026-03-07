// Method~HeaderRequest.swift

import Foundation

extension SwiftFulcrum.RPC.Method {
    func createHeaderRequest(_ header: Blockchain.Header, uuid: UUID) -> FulcrumRequest {
        switch header {
        case .get(let blockHash):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.SingleValueModel(value: blockHash))
        }
    }

    func createHeadersRequest(_ headers: Blockchain.Headers, uuid: UUID) -> FulcrumRequest {
        switch headers {
        case .getTip:
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.EmptyModel())

        case .subscribe:
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.EmptyModel())

        case .unsubscribe:
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.EmptyModel())
        }
    }
}

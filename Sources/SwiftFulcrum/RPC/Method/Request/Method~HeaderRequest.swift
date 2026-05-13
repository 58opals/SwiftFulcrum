// Method~HeaderRequest.swift

import Foundation

extension SwiftFulcrum.RPC.Method {
    func createHeaderRequest(_ header: Blockchain.Header, uuid: UUID) -> FulcrumRequest {
        switch header {
        case .get(let blockHash):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.SingleValue(value: blockHash))
        }
    }

    func createHeadersRequest(_ headers: Blockchain.Headers, uuid: UUID) -> FulcrumRequest {
        switch headers {
        case .getTip, .subscribe, .unsubscribe:
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.Empty())
        }
    }
}

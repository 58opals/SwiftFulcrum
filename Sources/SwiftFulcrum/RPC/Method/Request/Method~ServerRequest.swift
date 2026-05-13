// Method~ServerRequest.swift

import Foundation

extension SwiftFulcrum.RPC.Method {
    func createServerRequest(_ server: Server, uuid: UUID) -> FulcrumRequest {
        switch server {
        case .ping:
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.Empty())

        case .version(let clientName, let negotiationArgument):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.Pair(
                                      first: clientName,
                                      second: negotiationArgument
                                  ))

        case .features:
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.Empty())
        }
    }
}

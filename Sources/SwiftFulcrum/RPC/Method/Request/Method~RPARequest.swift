// Method~RPARequest.swift

import Foundation

extension SwiftFulcrum.RPC.Method {
    func createRPARequest(
        _ rpa: Blockchain.RPA,
        uuid: UUID
    ) -> FulcrumRequest {
        switch rpa {
        case .getHistory(let prefix, let fromHeight, let toHeight):
            return FulcrumRequest(
                id: uuid,
                method: self,
                params: RPCRequestParametersModel.RPAHistory(
                    prefix: prefix,
                    fromHeight: fromHeight,
                    toHeight: toHeight
                )
            )

        case .getMempool(let prefix):
            return FulcrumRequest(
                id: uuid,
                method: self,
                params: RPCRequestParametersModel.SingleValue(value: prefix)
            )
        }
    }
}

// Method~ScriptHashRequest.swift

import Foundation

extension SwiftFulcrum.RPC.Method {
    func createScriptHashRequest(
        _ scripthash: Blockchain.ScriptHash,
        uuid: UUID
    ) -> FulcrumRequest {
        switch scripthash {
        case .getBalance(let scripthash, let tokenFilter):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.OptionalTokenFilter(
                                      identifier: scripthash,
                                      tokenFilter: tokenFilter
                                  ))

        case .getFirstUse(let scripthash):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.SingleValue(value: scripthash))

        case .getHistory(let scripthash, let fromHeight, let toHeight, let shouldIncludeUnconfirmed):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.History(
                                      identifier: scripthash,
                                      fromHeight: fromHeight,
                                      toHeight: toHeight,
                                      shouldIncludeUnconfirmed: shouldIncludeUnconfirmed
                                  ))

        case .getMempool(let scripthash):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.SingleValue(value: scripthash))

        case .listUnspent(let scripthash, let tokenFilter):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.OptionalTokenFilter(
                                      identifier: scripthash,
                                      tokenFilter: tokenFilter
                                  ))

        case .subscribe(let scripthash):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.SingleValue(value: scripthash))

        case .unsubscribe(let scripthash):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.SingleValue(value: scripthash))
        }
    }
}

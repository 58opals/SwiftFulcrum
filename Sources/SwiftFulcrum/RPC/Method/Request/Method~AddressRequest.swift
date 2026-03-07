// Method~AddressRequest.swift

import Foundation

extension SwiftFulcrum.RPC.Method {
    func createAddressRequest(_ address: Blockchain.Address, uuid: UUID) -> FulcrumRequest {
        switch address {
        case .getBalance(let address, let tokenFilter):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.OptionalTokenFilterModel(
                                      identifier: address,
                                      tokenFilter: tokenFilter
                                  ))

        case .getFirstUse(let address):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.SingleValueModel(value: address))

        case .getHistory(let address, let fromHeight, let toHeight, let shouldIncludeUnconfirmed):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.HistoryModel(
                                      identifier: address,
                                      fromHeight: fromHeight,
                                      toHeight: toHeight,
                                      shouldIncludeUnconfirmed: shouldIncludeUnconfirmed
                                  ))

        case .getMempool(let address):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.SingleValueModel(value: address))

        case .getScriptHash(let address):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.SingleValueModel(value: address))

        case .listUnspent(let address, let tokenFilter):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.OptionalTokenFilterModel(
                                      identifier: address,
                                      tokenFilter: tokenFilter
                                  ))

        case .subscribe(let address):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.SingleValueModel(value: address))

        case .unsubscribe(let address):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.SingleValueModel(value: address))
        }
    }
}

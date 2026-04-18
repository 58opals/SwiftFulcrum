// Method~BlockRequest.swift

import Foundation

extension SwiftFulcrum.RPC.Method {
    func createBlockRequest(_ block: Blockchain.Block, uuid: UUID) -> FulcrumRequest {
        switch block {
        case .header(let height, let checkpointHeight):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.PairModel(
                                      first: height,
                                      second: checkpointHeight ?? 0
                                  ))

        case .headers(let startHeight, let count, let checkpointHeight):
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.TripleModel(
                                      first: startHeight,
                                      second: count,
                                      third: checkpointHeight ?? 0
                                  ))
        }
    }
}

// Method~BlockRequest.swift

import Foundation

extension SwiftFulcrum.RPC.Method {
    func createBlockRequest(_ block: Blockchain.Block, uuid: UUID) -> FulcrumRequest {
        switch block {
        case .header(let height, let checkpointHeight):
            let resolvedCheckpointHeight: UInt
            if let checkpointHeight {
                resolvedCheckpointHeight = checkpointHeight
            } else {
                let (incrementedHeight, didOverflow) = height.addingReportingOverflow(1)
                resolvedCheckpointHeight = didOverflow ? height : incrementedHeight
            }
            return FulcrumRequest(id: uuid,
                                  method: self,
                                  params: RPCRequestParametersModel.PairModel(
                                      first: height,
                                      second: resolvedCheckpointHeight
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

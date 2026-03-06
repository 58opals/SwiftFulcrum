import Foundation

extension SwiftFulcrum.RPC.Method {
    func createBlockRequest(_ block: Blockchain.Block, uuid: UUID) -> FulcrumRequest {
        switch block {
        case .header(let height, let checkpointHeight):
            struct ParametersModel: Encodable {
                let height: UInt
                let checkpointHeight: UInt
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(height)
                    try container.encode(checkpointHeight)
                }
            }
            let resolvedCheckpointHeight: UInt
            if let checkpointHeight {
                resolvedCheckpointHeight = checkpointHeight
            } else {
                let (incrementedHeight, didOverflow) = height.addingReportingOverflow(1)
                resolvedCheckpointHeight = didOverflow ? height : incrementedHeight
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(height: height,
                                              checkpointHeight: resolvedCheckpointHeight))

        case .headers(let startHeight, let count, let checkpointHeight):
            struct ParametersModel: Encodable {
                let startHeight: UInt
                let count: UInt
                let checkpointHeight: UInt
                func encode(to encoder: Encoder) throws {
                    var container = encoder.unkeyedContainer()
                    try container.encode(startHeight)
                    try container.encode(count)
                    try container.encode(checkpointHeight)
                }
            }
            return FulcrumRequest(id: uuid,
                           method: self,
                           params: ParametersModel(startHeight: startHeight,
                                              count: count,
                                              checkpointHeight: checkpointHeight ?? 0))
        }
    }
}

// SwiftFulcrum.API.Blockchain+Block.swift

extension SwiftFulcrum.API.Blockchain {
    public struct Block: Sendable {
        public func header(
            height: UInt,
            checkpointHeight: UInt? = nil
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Block.Header> {
            .init(method: .blockchain(.block(.header(height: height, checkpointHeight: checkpointHeight))))
        }

        public func headers(
            startHeight: UInt,
            count: UInt,
            checkpointHeight: UInt? = nil
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Block.Headers> {
            .init(
                method: .blockchain(
                    .block(.headers(startHeight: startHeight, count: count, checkpointHeight: checkpointHeight))
                )
            )
        }
    }
}

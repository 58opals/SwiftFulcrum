// SwiftFulcrum.API.Blockchain+Header.swift

extension SwiftFulcrum.API.Blockchain {
    public struct Header: Sendable {
        public func lookup(
            blockHash: String
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.Header.Lookup> {
            .init(method: .blockchain(.header(.get(blockHash: blockHash))))
        }
    }
}

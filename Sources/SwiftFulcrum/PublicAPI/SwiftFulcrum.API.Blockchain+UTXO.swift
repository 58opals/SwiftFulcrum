// SwiftFulcrum.API.Blockchain+UTXO.swift

extension SwiftFulcrum.API.Blockchain {
    public struct UTXO: Sendable {
        public func info(
            transactionHash: String,
            outputIndex: UInt
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.UTXO.Info> {
            .init(method: .blockchain(.utxo(.getInfo(transactionHash: transactionHash, outputIndex: outputIndex))))
        }
    }
}

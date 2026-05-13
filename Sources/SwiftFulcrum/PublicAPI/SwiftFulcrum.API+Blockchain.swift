// SwiftFulcrum.API+Blockchain.swift

extension SwiftFulcrum.API {
    public struct Blockchain: Sendable {
        public var scriptHash: ScriptHash { .init() }
        public var address: Address { .init() }
        public var block: Block { .init() }
        public var header: Header { .init() }
        public var headers: Headers { .init() }
        public var transaction: Transaction { .init() }
        public var utxo: UTXO { .init() }

        public func estimateFee(numberOfBlocks: Int) -> Request<SwiftFulcrum.Response.Blockchain.EstimateFee> {
            .init(method: .blockchain(.estimateFee(numberOfBlocks: numberOfBlocks)))
        }

        public var relayFee: Request<SwiftFulcrum.Response.Blockchain.RelayFee> {
            .init(method: .blockchain(.relayFee))
        }
    }
}

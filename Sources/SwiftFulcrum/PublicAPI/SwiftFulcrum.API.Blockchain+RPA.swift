// SwiftFulcrum.API.Blockchain+RPA.swift

extension SwiftFulcrum.API.Blockchain {
    /// Reusable payment address prefix-search requests.
    ///
    /// This typed surface requires a negotiated Electrum Cash protocol version of 1.6.0 or newer
    /// and a server that advertises RPA support through `server.features`.
    public struct RPA: Sendable {
        /// Returns confirmed transactions whose RPA prefix matches `prefix`.
        ///
        /// `fromHeight` is inclusive. `toHeight` is exclusive; omit it to encode the protocol's
        /// `-1` value, which lets the server scan toward the chain tip subject to its advertised
        /// history block limit. The result remains subject to the server's advertised maximum
        /// history item count.
        public func history(
            prefix: String,
            fromHeight: UInt,
            toHeight: UInt? = nil
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.RPA.History> {
            .init(
                method: .blockchain(
                    .rpa(
                        .getHistory(
                            prefix: prefix,
                            fromHeight: fromHeight,
                            toHeight: toHeight
                        )
                    )
                )
            )
        }

        /// Returns unconfirmed transactions whose RPA prefix matches `prefix`.
        public func mempool(
            prefix: String
        ) -> SwiftFulcrum.API.Request<SwiftFulcrum.Response.Blockchain.RPA.Mempool> {
            .init(method: .blockchain(.rpa(.getMempool(prefix: prefix))))
        }
    }
}

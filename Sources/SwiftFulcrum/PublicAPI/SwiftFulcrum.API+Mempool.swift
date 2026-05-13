// SwiftFulcrum.API+Mempool.swift

extension SwiftFulcrum.API {
    public struct Mempool: Sendable {
        public var info: Request<SwiftFulcrum.Response.Mempool.Info> {
            .init(method: .mempool(.getInfo))
        }

        public var feeHistogram: Request<SwiftFulcrum.Response.Mempool.FeeHistogram> {
            .init(method: .mempool(.getFeeHistogram))
        }
    }
}

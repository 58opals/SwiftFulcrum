// JSONRPC.Result+Blockchain.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result {
    public struct Blockchain {
        public typealias EstimateFee = Double
        public typealias RelayFee = Double
    }
}

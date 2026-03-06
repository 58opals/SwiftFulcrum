import Foundation

extension SwiftFulcrum.RPC.Response.Result {
    public struct Mempool {
        public struct GetInfo: SwiftFulcrum.RPC.ResponseProtocol {
            public let mempoolMinimumFee: Double?
            public let minimumRelayTransactionFee: Double?
            public let incrementalRelayFee: Double?
            public let unbroadcastCount: Int?
            public let isFullReplaceByFeeEnabled: Bool?
            
            public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Mempool.GetInfo
            public init(fromRPC jsonrpc: JSONRPC) {
                self.mempoolMinimumFee = jsonrpc.mempoolminfee?.value
                self.minimumRelayTransactionFee = jsonrpc.minrelaytxfee?.value
                self.incrementalRelayFee = jsonrpc.incrementalrelayfee?.value
                self.unbroadcastCount = jsonrpc.unbroadcastcount
                self.isFullReplaceByFeeEnabled = jsonrpc.isFullReplaceByFeeEnabled
            }
        }
        
        public struct GetFeeHistogram: SwiftFulcrum.RPC.ResponseProtocol {
            public let histogram: [Result]
            
            public struct Result: Decodable, Sendable {
                public let fee: Double
                public let virtualSize: UInt
                
                init(from pair: SwiftFulcrum.RPC.Response.JSONRPC.Result.Mempool.FeeHistogram) throws {
                    guard pair.count == 2 else { throw SwiftFulcrum.RPC.Response.Result.Error.unexpectedFormat("Histogram entry must be [fee, vsize]; got \(pair)") }
                    let feeValue = pair[0].value
                    let virtualSizeValue = pair[1].value
                    guard feeValue.isFinite, feeValue >= 0 else { throw SwiftFulcrum.RPC.Response.Result.Error.unexpectedFormat("Invalid fee: \(feeValue)") }
                    guard virtualSizeValue.isFinite, virtualSizeValue >= 0, virtualSizeValue <= Double(UInt.max) else { throw SwiftFulcrum.RPC.Response.Result.Error.unexpectedFormat("Invalid vsize: \(virtualSizeValue)") }
                    
                    self.fee = feeValue
                    self.virtualSize = UInt(virtualSizeValue.rounded(.towardZero))
                }
            }
            
            public typealias JSONRPC = SwiftFulcrum.RPC.Response.JSONRPC.Result.Mempool.GetFeeHistogram
            public init(fromRPC jsonrpc: JSONRPC) throws {
                self.histogram = try jsonrpc.enumerated().map { index, pair in
                    do { return try Result(from: pair) }
                    catch { throw SwiftFulcrum.RPC.Response.Result.Error.unexpectedFormat("Malformed entry at index \(index): \(error)") }
                }.sorted { $0.fee < $1.fee }
            }
        }
    }
}

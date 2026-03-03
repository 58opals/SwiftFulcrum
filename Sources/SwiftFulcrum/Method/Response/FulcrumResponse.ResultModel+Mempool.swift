import Foundation

extension FulcrumResponse.ResultModel {
    public struct Mempool {
        public struct GetInfo: JSONRPCResponse {
            public let mempoolMinimumFee: Double?
            public let minimumRelayTransactionFee: Double?
            public let incrementalRelayFee: Double?
            public let unbroadcastCount: Int?
            public let isFullReplaceByFeeEnabled: Bool?
            
            public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Mempool.GetInfo
            public init(fromRPC jsonrpc: JSONRPCModel) {
                self.mempoolMinimumFee = jsonrpc.mempoolminfee?.value
                self.minimumRelayTransactionFee = jsonrpc.minrelaytxfee?.value
                self.incrementalRelayFee = jsonrpc.incrementalrelayfee?.value
                self.unbroadcastCount = jsonrpc.unbroadcastcount
                self.isFullReplaceByFeeEnabled = jsonrpc.isFullReplaceByFeeEnabled
            }
        }
        
        public struct GetFeeHistogram: JSONRPCResponse {
            public let histogram: [Result]
            
            public struct Result: Decodable, Sendable {
                public let fee: Double
                public let virtualSize: UInt
                
                init(from pair: FulcrumResponse.JSONRPCModel.Result.Mempool.FeeHistogram) throws {
                    guard pair.count == 2 else { throw FulcrumResponse.ResultModel.Error.unexpectedFormat("Histogram entry must be [fee, vsize]; got \(pair)") }
                    let feeValue = pair[0].value
                    let virtualSizeValue = pair[1].value
                    guard feeValue.isFinite, feeValue >= 0 else { throw FulcrumResponse.ResultModel.Error.unexpectedFormat("Invalid fee: \(feeValue)") }
                    guard virtualSizeValue.isFinite, virtualSizeValue >= 0, virtualSizeValue <= Double(UInt.max) else { throw FulcrumResponse.ResultModel.Error.unexpectedFormat("Invalid vsize: \(virtualSizeValue)") }
                    
                    self.fee = feeValue
                    self.virtualSize = UInt(virtualSizeValue.rounded(.towardZero))
                }
            }
            
            public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Mempool.GetFeeHistogram
            public init(fromRPC jsonrpc: JSONRPCModel) throws {
                self.histogram = try jsonrpc.enumerated().map { index, pair in
                    do { return try Result(from: pair) }
                    catch { throw FulcrumResponse.ResultModel.Error.unexpectedFormat("Malformed entry at index \(index): \(error)") }
                }.sorted { $0.fee < $1.fee }
            }
        }
    }
}

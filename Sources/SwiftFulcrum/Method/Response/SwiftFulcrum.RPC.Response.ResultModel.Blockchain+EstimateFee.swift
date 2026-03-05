import Foundation

extension SwiftFulcrum.RPC.Response.ResultModel.Blockchain {
        public struct EstimateFee: SwiftFulcrum.RPC.ResponseProtocol {
            public let fee: Double
            
            public typealias JSONRPCModel = SwiftFulcrum.RPC.Response.JSONRPCModel.Result.Blockchain.EstimateFee
            public init(fromRPC jsonrpc: JSONRPCModel) {
                self.fee = jsonrpc
            }
        }
        

}

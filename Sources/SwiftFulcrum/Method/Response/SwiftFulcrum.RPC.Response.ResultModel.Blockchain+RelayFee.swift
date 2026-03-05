import Foundation

extension SwiftFulcrum.RPC.Response.ResultModel.Blockchain {
        public struct RelayFee: SwiftFulcrum.RPC.ResponseProtocol {
            public let fee: Double
            
            public typealias JSONRPCModel = SwiftFulcrum.RPC.Response.JSONRPCModel.Result.Blockchain.RelayFee
            public init(fromRPC jsonrpc: JSONRPCModel) {
                self.fee = jsonrpc
            }
        }
        

}

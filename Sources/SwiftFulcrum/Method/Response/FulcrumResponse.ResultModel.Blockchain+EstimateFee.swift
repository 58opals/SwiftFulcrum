import Foundation

extension FulcrumResponse.ResultModel.Blockchain {
        public struct EstimateFee: JSONRPCResponse {
            public let fee: Double
            
            public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Blockchain.EstimateFee
            public init(fromRPC jsonrpc: JSONRPCModel) {
                self.fee = jsonrpc
            }
        }
        

}

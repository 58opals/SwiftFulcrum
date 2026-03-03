import Foundation

extension FulcrumResponse.ResultModel.Blockchain {
        public struct RelayFee: JSONRPCResponse {
            public let fee: Double
            
            public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Blockchain.RelayFee
            public init(fromRPC jsonrpc: JSONRPCModel) {
                self.fee = jsonrpc
            }
        }
        

}

import Foundation

extension FulcrumResponse.ResultModel.BlockchainModel {
        public struct EstimateFeeModel: JSONRPCResponse {
            public let fee: Double
            
            public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.EstimateFeeModel
            public init(fromRPC jsonrpc: JSONRPCModel) {
                self.fee = jsonrpc
            }
        }
        

}

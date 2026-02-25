import Foundation

extension FulcrumResponse.ResultModel.BlockchainModel {
        public struct RelayFeeModel: JSONRPCResponse {
            public let fee: Double
            
            public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.RelayFeeModel
            public init(fromRPC jsonrpc: JSONRPCModel) {
                self.fee = jsonrpc
            }
        }
        

}

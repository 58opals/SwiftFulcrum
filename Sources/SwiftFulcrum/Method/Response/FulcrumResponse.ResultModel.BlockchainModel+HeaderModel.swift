import Foundation

extension FulcrumResponse.ResultModel.BlockchainModel {
        public struct HeaderModel {
            public struct GetModel: JSONRPCResponse {
                public let height: UInt
                public let hex: String
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.HeaderModel.GetModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.height = jsonrpc.height
                    self.hex = jsonrpc.hex
                }
            }
        }
        

}

import Foundation

extension FulcrumResponse.ResultModel.Blockchain {
        public struct Header {
            public struct Get: JSONRPCResponse {
                public let height: UInt
                public let hex: String
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Blockchain.Header.Get
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.height = jsonrpc.height
                    self.hex = jsonrpc.hex
                }
            }
        }
        

}

import Foundation

extension SwiftFulcrum.RPC.Response.ResultModel.Blockchain {
        public struct Header {
            public struct Get: SwiftFulcrum.RPC.ResponseProtocol {
                public let height: UInt
                public let hex: String
                
                public typealias JSONRPCModel = SwiftFulcrum.RPC.Response.JSONRPCModel.Result.Blockchain.Header.Get
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.height = jsonrpc.height
                    self.hex = jsonrpc.hex
                }
            }
        }
        

}

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPCModel.Result.Blockchain {
            public struct Header {
                public struct Get: Decodable, Sendable {
                    public let height: UInt
                    public let hex: String
                }
            }
            

}

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain {
            public struct Header {
                public struct Get: Decodable, Sendable {
                    public let height: UInt
                    public let hex: String
                }
            }
            

}

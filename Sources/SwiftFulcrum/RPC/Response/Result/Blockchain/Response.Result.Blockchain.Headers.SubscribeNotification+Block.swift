// Response.Result.Blockchain.Headers.SubscribeNotification+Block.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.SubscribeNotification {
    public struct Block: Decodable, Sendable {
        public let height: UInt
        public let hex: String
    }
}

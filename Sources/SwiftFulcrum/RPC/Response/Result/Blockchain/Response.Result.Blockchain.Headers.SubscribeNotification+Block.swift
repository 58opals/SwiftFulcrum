// Response.Result.Blockchain.Headers.SubscribeNotification+Block.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain.Headers.SubscribeNotification {
    public struct Block: Decodable, Sendable {
        public let height: UInt
        public let hex: String
    }
}

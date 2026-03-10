// Response.Result.Blockchain+Headers.swift

import Foundation

extension SwiftFulcrum.RPC.Response.Result.Blockchain {
    public struct Headers {
        public struct GetTip: Decodable, Sendable {
            public let height: UInt
            public let hex: String

            public init(from decoder: Decoder) throws {
                let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Headers.GetTip(from: decoder)
                self.height = payloadModel.height
                self.hex = payloadModel.hex
            }
        }
        
        public struct Subscribe: Decodable, Sendable {
            public let height: UInt
            public let hex: String

            public init(from decoder: Decoder) throws {
                let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Headers.Subscribe(from: decoder)
                switch payloadModel {
                case .topHeader(let tip):
                    self.height = tip.height
                    self.hex = tip.hex
                case .newHeader(let batch) where batch.count == 1:
                    self.height = batch[0].height
                    self.hex = batch[0].hex
                case .newHeader(let batch):
                    throw ResponseResultDecodeError.unexpectedFormat("Expected single top header; received batch of new headers: \(batch.description)")
                }
            }
        }
        
        public struct SubscribeNotification: Decodable, Sendable {
            public let subscriptionIdentifier: String
            public let blocks: [Block]

            public struct Block: Decodable, Sendable {
                public let height: UInt
                public let hex: String
            }

            public init(from decoder: Decoder) throws {
                let payloadModel = try SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain.Headers.Subscribe(from: decoder)
                self.subscriptionIdentifier = SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe)).path

                switch payloadModel {
                case .newHeader(let list):
                    guard !list.isEmpty else { throw ResponseResultDecodeError.missingField("header list empty") }
                    self.blocks = list.map { Block(height: $0.height, hex: $0.hex) }
                case .topHeader(let tip):
                    self.blocks = [Block(height: tip.height, hex: tip.hex)]
                }
            }
        }
        
        public struct Unsubscribe: Decodable, Sendable {
            public let isSuccess: Bool

            public init(from decoder: Decoder) throws {
                self.isSuccess = try Bool(from: decoder)
            }
        }
    }
}

import Foundation

extension SwiftFulcrum.RPC.Response.ResultModel.Blockchain {
        public struct Headers {
            public struct GetTip: SwiftFulcrum.RPC.ResponseProtocol {
                public let height: UInt
                public let hex: String
                
                public typealias JSONRPCModel = SwiftFulcrum.RPC.Response.JSONRPCModel.Result.Blockchain.Headers.GetTip
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.height = jsonrpc.height
                    self.hex = jsonrpc.hex
                }
            }
            
            public struct Subscribe: SwiftFulcrum.RPC.ResponseProtocol {
                public let height: UInt
                public let hex: String
                
                public typealias JSONRPCModel = SwiftFulcrum.RPC.Response.JSONRPCModel.Result.Blockchain.Headers.Subscribe
                public init(fromRPC jsonrpc: JSONRPCModel) throws {
                    switch jsonrpc {
                    case .topHeader(let tip):
                        self.height = tip.height
                        self.hex = tip.hex
                    case .newHeader(let batch) where batch.count == 1:
                        self.height = batch[0].height
                        self.hex = batch[0].hex
                    case .newHeader(let batch):
                        throw SwiftFulcrum.RPC.Response.ResultModel.Error.unexpectedFormat("Expected single top header; received batch of new headers: \(batch.description)")
                    }
                }
            }
            
            public struct SubscribeNotification: SwiftFulcrum.RPC.ResponseProtocol {
                public let subscriptionIdentifier: String
                public let blocks: [Block]
                
                public struct Block: Decodable, Sendable {
                    public let height: UInt
                    public let hex: String
                }
                
                public typealias JSONRPCModel = SwiftFulcrum.RPC.Response.JSONRPCModel.Result.Blockchain.Headers.Subscribe
                public init(fromRPC jsonrpc: JSONRPCModel) throws {
                    self.subscriptionIdentifier = SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe)).path
                    
                    switch jsonrpc {
                    case .newHeader(let list):
                        guard !list.isEmpty else { throw SwiftFulcrum.RPC.Response.ResultModel.Error.missingField("header list empty") }
                        self.blocks = list.map { Block(height: $0.height, hex: $0.hex) }
                    case .topHeader(let tip):
                        self.blocks = [Block(height: tip.height, hex: tip.hex)]
                    }
                }
            }
            
            public struct Unsubscribe: SwiftFulcrum.RPC.ResponseProtocol {
                public let isSuccess: Bool
                
                public typealias JSONRPCModel = SwiftFulcrum.RPC.Response.JSONRPCModel.Result.Blockchain.Headers.Unsubscribe
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.isSuccess = jsonrpc
                }
            }
        }
        

}

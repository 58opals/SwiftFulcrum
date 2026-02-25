import Foundation

extension FulcrumResponse.ResultModel.BlockchainModel {
        public struct HeadersModel {
            public struct GetTipModel: JSONRPCResponse {
                public let height: UInt
                public let hex: String
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.HeadersModel.GetTipModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.height = jsonrpc.height
                    self.hex = jsonrpc.hex
                }
            }
            
            public struct SubscribeModel: JSONRPCResponse {
                public let height: UInt
                public let hex: String
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.HeadersModel.SubscribeModel
                public init(fromRPC jsonrpc: JSONRPCModel) throws {
                    switch jsonrpc {
                    case .topHeader(let tip):
                        self.height = tip.height
                        self.hex = tip.hex
                    case .newHeader(let batch) where batch.count == 1:
                        self.height = batch[0].height
                        self.hex = batch[0].hex
                    case .newHeader(let batch):
                        throw FulcrumResponse.ResultModel.Error.unexpectedFormat("Expected single top header; received batch of new headers: \(batch.description)")
                    }
                }
            }
            
            public struct SubscribeNotificationModel: JSONRPCResponse {
                public let subscriptionIdentifier: String
                public let blocks: [BlockModel]
                
                public struct BlockModel: Decodable, Sendable {
                    public let height: UInt
                    public let hex: String
                }
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.HeadersModel.SubscribeModel
                public init(fromRPC jsonrpc: JSONRPCModel) throws {
                    self.subscriptionIdentifier = FulcrumMethodRequest.blockchain(.headers(.subscribe)).path
                    
                    switch jsonrpc {
                    case .newHeader(let list):
                        guard !list.isEmpty else { throw FulcrumResponse.ResultModel.Error.missingField("header list empty") }
                        self.blocks = list.map { BlockModel(height: $0.height, hex: $0.hex) }
                    case .topHeader(let tip):
                        self.blocks = [BlockModel(height: tip.height, hex: tip.hex)]
                    }
                }
            }
            
            public struct UnsubscribeModel: JSONRPCResponse {
                public let isSuccess: Bool
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel.HeadersModel.UnsubscribeModel
                public init(fromRPC jsonrpc: JSONRPCModel) {
                    self.isSuccess = jsonrpc
                }
            }
        }
        

}

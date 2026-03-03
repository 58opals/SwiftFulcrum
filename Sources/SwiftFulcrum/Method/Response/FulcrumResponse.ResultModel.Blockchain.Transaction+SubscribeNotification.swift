import Foundation

extension FulcrumResponse.ResultModel.Blockchain.Transaction {
            public struct SubscribeNotification: JSONRPCResponse {
                public let subscriptionIdentifier: String
                public let transactionHash: String
                public let height: UInt
                
                public typealias JSONRPCModel = FulcrumResponse.JSONRPCModel.Result.Blockchain.Transaction.Subscribe
                public init(fromRPC jsonrpc: JSONRPCModel) throws {
                    switch jsonrpc {
                    case .transactionHashAndHeight(let pairs):
                        var hashValue: String?
                        var heightValue: UInt?
                        
                        for pair in pairs {
                            switch pair {
                            case .transactionHash(let transactionHash):
                                guard hashValue == nil else { throw FulcrumResponse.ResultModel.Error.unexpectedFormat("Duplicate transaction hash in notification payload") }
                                hashValue = transactionHash
                            case .height(let height):
                                guard heightValue == nil else { throw FulcrumResponse.ResultModel.Error.unexpectedFormat("Duplicate height in notification payload") }
                                heightValue = height
                            }
                        }
                        
                        guard let transactionHash = hashValue else { throw FulcrumResponse.ResultModel.Error.missingField("transactionHash") }
                        guard let height = heightValue else { throw FulcrumResponse.ResultModel.Error.missingField("height") }
                        
                        self.subscriptionIdentifier = transactionHash
                        self.transactionHash = transactionHash
                        self.height = height
                    case .height(let height):
                        throw FulcrumResponse.ResultModel.Error.unexpectedFormat("Expected [txid, height] for Transaction.Subscribe; got height only: \(height.description)")
                    }
                }
            }
            

}

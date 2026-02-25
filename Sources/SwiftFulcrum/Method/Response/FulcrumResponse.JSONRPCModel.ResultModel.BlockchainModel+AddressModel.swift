import Foundation

extension FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel {
            public struct AddressModel {
                public struct GetBalanceModel: Decodable, Sendable {
                    public let confirmed: UInt64
                    public let unconfirmed: Int64
                }
                
                public struct GetFirstUseModel: Decodable, Sendable {
                    public let block_hash: String
                    public let height: UInt
                    public let tx_hash: String
                }
                
                public typealias GetHistoryModel = [GetHistoryItemModel]
                public struct GetHistoryItemModel: Decodable, Sendable {
                    public let height: Int
                    public let tx_hash: String
                    public let fee: UInt?
                }
                
                public typealias GetMempoolModel = [GetMempoolItemModel]
                public struct GetMempoolItemModel: Decodable, Sendable {
                    public let height: Int
                    public let tx_hash: String
                    public let fee: UInt?
                }
                
                public typealias GetScriptHashModel = String
                
                public typealias ListUnspentModel = [ListUnspentItemModel]
                public struct ListUnspentItemModel: Decodable, Sendable {
                    public let height: UInt
                    public let token_data: FulcrumMethodRequest.BlockchainModel.CashTokensModel.JSONModel?
                    public let tx_hash: String
                    public let tx_pos: UInt
                    public let value: UInt64
                }
                
                public typealias SubscribeModel = SubscribeParametersModel
                public enum SubscribeParametersModel: Decodable, Sendable {
                    case status(String)
                    case addressAndStatus([String?])
                    
                    public init(from decoder: Decoder) throws {
                        let container = try decoder.singleValueContainer()
                        
                        if let singleValue = try? container.decode(String.self) {
                            self = .status(singleValue)
                            return
                        }
                        
                        if let multipleValues = try? container.decode([String?].self) {
                            self = .addressAndStatus(multipleValues)
                            return
                        }
                        
                        throw DecodingError.typeMismatch(SubscribeParametersModel.self,
                                                         .init(codingPath: decoder.codingPath,
                                                               debugDescription: "Expected String or [String?]"))
                    }
                }
                
                public typealias UnsubscribeModel = Bool
            }
            

}

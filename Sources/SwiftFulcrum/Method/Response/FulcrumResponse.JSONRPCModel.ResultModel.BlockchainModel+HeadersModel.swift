import Foundation

extension FulcrumResponse.JSONRPCModel.ResultModel.BlockchainModel {
            public struct HeadersModel {
                public struct GetTipModel: Decodable, Sendable {
                    public let height: UInt
                    public let hex: String
                }
                
                public typealias SubscribeModel = SubscribeParametersModel
                public enum SubscribeParametersModel: Decodable, Sendable {
                    case topHeader(GetTipModel)
                    case newHeader([GetTipModel])
                    
                    public init(from decoder: Decoder) throws {
                        let container = try decoder.singleValueContainer()
                        
                        if let singleValue = try? container.decode(GetTipModel.self) {
                            self = .topHeader(singleValue)
                            return
                        }
                        
                        if let multipleValues = try? container.decode([GetTipModel].self) {
                            self = .newHeader(multipleValues)
                            return
                        }
                        
                        throw DecodingError.typeMismatch(SubscribeParametersModel.self,
                                                         .init(codingPath: decoder.codingPath,
                                                               debugDescription: "Expected top header's height and hex or new header's heights and hexes"))
                    }
                }
                
                public typealias UnsubscribeModel = Bool
            }
            

}

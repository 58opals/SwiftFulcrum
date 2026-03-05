import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPCModel.Result.Blockchain {
            public struct Headers {
                public struct GetTip: Decodable, Sendable {
                    public let height: UInt
                    public let hex: String
                }
                
                public typealias Subscribe = SubscribeParameters
                public enum SubscribeParameters: Decodable, Sendable {
                    case topHeader(GetTip)
                    case newHeader([GetTip])
                    
                    public init(from decoder: Decoder) throws {
                        let container = try decoder.singleValueContainer()
                        
                        if let singleValue = try? container.decode(GetTip.self) {
                            self = .topHeader(singleValue)
                            return
                        }
                        
                        if let multipleValues = try? container.decode([GetTip].self) {
                            self = .newHeader(multipleValues)
                            return
                        }
                        
                        throw DecodingError.typeMismatch(SubscribeParameters.self,
                                                         .init(codingPath: decoder.codingPath,
                                                               debugDescription: "Expected top header's height and hex or new header's heights and hexes"))
                    }
                }
                
                public typealias Unsubscribe = Bool
            }
            

}

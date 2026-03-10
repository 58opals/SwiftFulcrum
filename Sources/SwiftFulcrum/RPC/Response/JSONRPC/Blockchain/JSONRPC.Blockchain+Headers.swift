// JSONRPC.Blockchain+Headers.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain {
    struct Headers {
        struct GetTip: Decodable, Sendable {
            let height: UInt
            let hex: String
        }

        typealias Subscribe = SubscribeParameters
        enum SubscribeParameters: Decodable, Sendable {
                    case topHeader(GetTip)
                    case newHeader([GetTip])
                    
                    init(from decoder: Decoder) throws {
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

        typealias Unsubscribe = Bool
    }
}

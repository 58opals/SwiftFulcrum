// JSONRPC.Blockchain+Address.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain {
            public struct Address {
                public struct GetBalance: Decodable, Sendable {
                    public let confirmed: UInt64
                    public let unconfirmed: Int64
                }
                
                public struct GetFirstUse: Decodable, Sendable {
                    public let block_hash: String
                    public let height: UInt
                    public let tx_hash: String
                }
                
                public typealias GetHistory = [GetHistoryItem]
                public struct GetHistoryItem: Decodable, Sendable {
                    public let height: Int
                    public let tx_hash: String
                    public let fee: UInt?
                }
                
                public typealias GetMempool = [GetMempoolItem]
                public struct GetMempoolItem: Decodable, Sendable {
                    public let height: Int
                    public let tx_hash: String
                    public let fee: UInt?
                }
                
                public typealias GetScriptHash = String
                
                public typealias ListUnspent = [ListUnspentItem]
                public struct ListUnspentItem: Decodable, Sendable {
                    public let height: UInt
                    public let token_data: SwiftFulcrum.RPC.Method.Blockchain.CashTokens.JSON?
                    public let tx_hash: String
                    public let tx_pos: UInt
                    public let value: UInt64
                }
                
                public typealias Subscribe = SubscribeParameters
                public enum SubscribeParameters: Decodable, Sendable {
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
                        
                        throw DecodingError.typeMismatch(SubscribeParameters.self,
                                                         .init(codingPath: decoder.codingPath,
                                                               debugDescription: "Expected String or [String?]"))
                    }
                }
                
                public typealias Unsubscribe = Bool
            }
            

}

// JSONRPC.Blockchain+ScriptHash.swift

import Foundation

extension SwiftFulcrum.RPC.Response.JSONRPC.Result.Blockchain {
    struct ScriptHash {
        struct GetBalance: Decodable, Sendable {
            let confirmed: UInt64
            let unconfirmed: Int64
        }

        struct GetFirstUse: Decodable, Sendable {
            let block_hash: String
            let height: UInt
            let tx_hash: String
        }

        typealias GetHistory = [GetHistoryItem]
        struct GetHistoryItem: Decodable, Sendable {
            let height: Int
            let tx_hash: String
            let fee: UInt?
        }

        typealias GetMempool = [GetMempoolItem]
        struct GetMempoolItem: Decodable, Sendable {
            let height: Int
            let tx_hash: String
            let fee: UInt?
        }

        typealias ListUnspent = [ListUnspentItem]
        struct ListUnspentItem: Decodable, Sendable {
            let height: UInt
            let token_data: SwiftFulcrum.RPC.Method.Blockchain.CashTokens.JSON?
            let tx_hash: String
            let tx_pos: UInt
            let value: UInt64
        }

        typealias Subscribe = SubscribeParameters
        enum SubscribeParameters: Decodable, Sendable {
                    case status(String)
                    case scripthashAndStatus([String?])
                    
                    init(from decoder: Decoder) throws {
                        let container = try decoder.singleValueContainer()
                        
                        if let singleValue = try? container.decode(String.self) {
                            self = .status(singleValue)
                            return
                        }
                        
                        if let multipleValues = try? container.decode([String?].self) {
                            self = .scripthashAndStatus(multipleValues)
                            return
                        }
                        
                        throw DecodingError.typeMismatch(SubscribeParameters.self,
                                                         .init(codingPath: decoder.codingPath,
                                                               debugDescription: "Expected String or [String?]"))
                    }
        }

        typealias Unsubscribe = Bool
    }
}

import Foundation

extension Response.Result.Blockchain {
    typealias EstimateFeeJSONRPCResult = Double
    typealias RelayFeeJSONRPCResult = Double
}

extension Response.Result.Blockchain.Address {
    struct GetBalanceJSONRPCResult: Decodable {
        let confirmed: UInt64
        let unconfirmed: Int64
    }
    
    struct GetFirstUseJSONRPCResult: Decodable {
        let block_hash: String
        let height: UInt
        let tx_hash: String
    }
    
    typealias GetHistoryJSONRPCResult = [GetHistoryJSONRPCResultItem]
    struct GetHistoryJSONRPCResultItem: Decodable {
        let height: Int
        let tx_hash: String
        let fee: UInt?
    }
    
    typealias GetMempoolJSONRPCResult = [GetMempoolJSONRPCResultItem]
    struct GetMempoolJSONRPCResultItem: Decodable {
        let height: Int
        let tx_hash: String
        let fee: UInt?
    }
    
    typealias GetScriptHashJSONRPCResult = String
    
    typealias ListUnspentJSONRPCResult = [ListUnspentJSONRPCResultItem]
    struct ListUnspentJSONRPCResultItem: Decodable {
        let height: UInt
        let token_data: Method.Blockchain.CashTokens.JSON?
        let tx_hash: String
        let tx_pos: UInt
        let value: UInt64
    }
    
    typealias Status = String
    typealias SubscribeJSONRPCResult = Status
    
    typealias SubscribeJSONRPCNotification = SubscribeJSONRPCNotificationParameters
    struct SubscribeJSONRPCNotificationParameters: Decodable {
        let address: String
        let status: Status?
        
        init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            self.address = try container.decode(String.self)
            self.status = try container.decodeIfPresent(String.self)
        }
    }
    
    typealias UnsubscribeJSONRPCResult = Bool
}

extension Response.Result.Blockchain.Block {
    struct HeaderJSONRPCResult: Decodable {
        let branch: [String]
        let header: String
        let root: String
    }
    
    struct HeadersJSONRPCResult: Decodable {
        let count: UInt
        let hex: String
        let max: UInt
    }
}

extension Response.Result.Blockchain.Header {
    struct GetJSONRPCResult: Decodable {
        let height: UInt
        let hex: String
    }
}

extension Response.Result.Blockchain.Headers {
    struct GetTipJSONRPCResult: Decodable {
        let height: UInt
        let hex: String
    }
    
    struct SubscribeJSONRPCResult: Decodable {
        let height: UInt
        let hex: String
    }
    
    typealias SubscribeJSONRPCNotification = [SubscribeJSONRPCNotificationParameters]
    struct SubscribeJSONRPCNotificationParameters: Decodable {
        let height: UInt
        let hex: String
    }
    
    typealias UnsubscribeJSONRPCResult = Bool
}

extension Response.Result.Blockchain.Transaction {
    typealias BroadcastJSONRPCResult = Bool
    
    struct GetJSONRPCResult: Decodable {
        let blockhash: String
        let blocktime: UInt
        let confirmations: UInt
        let hash: String
        let hex: String
        let locktime: UInt
        let size: UInt
        let time: UInt
        let txid: String
        let version: UInt
        let vin: [Input]
        let vout: [Output]
        
        struct Input: Decodable {
            let scriptSig: ScriptSig
            let sequence: UInt
            let txid: String
            let vout: UInt
            
            struct ScriptSig: Decodable {
                let asm: String
                let hex: String
            }
        }
        
        struct Output: Decodable {
            let n: UInt
            let scriptPubKey: ScriptPubKey
            let value: Double
            
            struct ScriptPubKey: Decodable {
                let addresses: [String]
                let asm: String
                let hex: String
                let reqSigs: UInt
                let type: String
            }
        }
    }
    
    struct GetConfirmedBlockHashJSONRPCResult: Decodable {
        let block_hash: String
        let block_header: String?
        let block_height: UInt
    }
    
    typealias GetHeightJSONRPCResult = UInt
    
    struct GetMerkleJSONRPCResult: Decodable {
        let merkle: [String]
        let block_height: UInt
        let pos: UInt
    }
    
    struct IDFromPosJSONRPCResult: Decodable {
        let merkle: [String]
        let tx_hash: String
    }
    
    typealias SubscribeJSONRPCResult = UInt
    
    typealias SubscribeJSONRPCNotification = SubscribeJSONRPCNotificationParameters
    struct SubscribeJSONRPCNotificationParameters: Decodable {
        let transactionHash: String
        let height: UInt
        
        init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            self.transactionHash = try container.decode(String.self)
            self.height = try container.decode(UInt.self)
        }
    }
    
    typealias UnsubscribeJSONRPCResult = Bool
}

extension Response.Result.Blockchain.Transaction.DSProof {
    struct GetJSONRPCResult: Decodable {
        let dspid: String
        let txid: String
        let hex: String
        let outpoint: Outpoint
        let descendants: [String]
        
        struct Outpoint: Decodable {
            let txid: String
            let vout: UInt
        }
    }
    
    typealias ListJSONRPCResult = [String]
    
    struct SubscribeJSONRPCResult: Decodable {
        let proof: GetJSONRPCResult
    }
    
    typealias SubscribeJSONRPCNotification = SubscribeJSONRPCNotificationParameters
    struct SubscribeJSONRPCNotificationParameters: Decodable {
        let transactionHash: String
        let dsProof: GetJSONRPCResult?
        
        init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            self.transactionHash = try container.decode(String.self)
            self.dsProof = try container.decodeIfPresent(GetJSONRPCResult.self)
        }
    }
    
    typealias UnsubscribeJSONRPCResult = Bool
}

extension Response.Result.Blockchain.UTXO {
    struct GetInfoJSONRPCResult: Decodable {
        let confirmed_height: UInt?
        let scripthash: String
        let value: UInt
        let token_data: Method.Blockchain.CashTokens.JSON?
    }
}

extension Response.Result.Mempool {
    typealias GetFeeHistogramJSONRPCResult = [[UInt]]
}

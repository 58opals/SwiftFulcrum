import Foundation

public enum Method {
    case blockchain(Blockchain)
    case mempool(Mempool)
    
    public enum Blockchain {
        case estimateFee(numberOfBlocks: Int)
        case relayFee
        
        case address(Address)
        case block(Block)
        case header(Header)
        case headers(Headers)
        case transaction(Transaction)
        case utxo(UTXO)
        
        public enum Address {
            public typealias fromHeight = UInt
            public typealias toHeight = UInt
            public typealias includeUnconfirmed = Bool
            
            case getBalance(address: String, tokenFilter: CashTokens.TokenFilter?)
            case getFirstUse(address: String)
            case getHistory(address: String, fromHeight: UInt?, toHeight: UInt?, includeUnconfirmed: Bool)
            case getMempool(address: String)
            case getScriptHash(address: String)
            case listUnspent(address: String, tokenFilter: CashTokens.TokenFilter?)
            case subscribe(address: String)
            case unsubscribe(address: String)
        }
        
        public enum Block {
            case header(height: UInt, checkpointHeight: UInt? = nil)
            case headers(startHeight: UInt, count: UInt, checkpointHeight: UInt? = nil)
        }
        
        public enum Header {
            case get(blockHash: String)
        }
        
        public enum Headers {
            case getTip
            case subscribe
            case unsubscribe
        }
        
        public enum Transaction {
            case broadcast(rawTransaction: String)
            case get(transactionHash: String, verbose: Bool)
            case getConfirmedBlockHash(transactionHash: String, includeHeader: Bool)
            case getHeight(transactionHash: String)
            case getMerkle(transactionHash: String)
            case idFromPos(blockHeight: UInt, transactionPosition: UInt, includeMerkleProof: Bool)
            case subscribe(transactionHash: String)
            case unsubscribe(transactionHash: String)
            
            case dsProof(DSProof)
            
            public enum DSProof {
                case get(transactionHash: String)
                case list
                case subscribe(transactionHash: String)
                case unsubscribe(transactionHash: String)
            }
        }
        
        public enum UTXO {
            case getInfo(transactionHash: String, outputIndex: UInt16)
        }
    }
    
    public enum Mempool {
        case getFeeHistogram
    }
}

// MARK: - CashTokens
extension Method.Blockchain {
    public struct CashTokens {
        public struct JSON: Codable {
            public let amount: String
            public let category: String
            public let nft: NFT?
            
            public struct NFT: Codable {
                public let capability: Capability
                public let commitment: String
                
                public enum Capability: Codable {
                    case none
                    case mutable
                    case minting
                }
            }
        }
        
        public enum TokenFilter: String, Codable {
            case include = "include_tokens"
            case exclude = "exclude_tokens"
            case only = "tokens_only"
        }
    }
}

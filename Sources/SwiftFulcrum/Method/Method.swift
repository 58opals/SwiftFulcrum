import Foundation

public enum Method {
    case blockchain(Blockchain)
    case mempool(Mempool)
    
    public enum Blockchain {
        public typealias numberOfBlocks = Int
        case estimateFee(numberOfBlocks)
        case relayFee
        
        case address(Address)
        case block(Block)
        case header(Header)
        case headers(Headers)
        case transaction(Transaction)
        case utxo(UTXO)
        
        public enum Address {
            public typealias address = String
            public typealias tokenFilter = CashTokens.TokenFilter
            public typealias fromHeight = UInt
            public typealias toHeight = UInt
            public typealias includeUnconfirmed = Bool
            
            case getBalance(address, tokenFilter?)
            case getFirstUse(address)
            case getHistory(address, fromHeight?, toHeight?, includeUnconfirmed)
            case getMempool(address)
            case getScriptHash(address)
            case listUnspent(address, tokenFilter?)
            case subscribe(address)
            case unsubscribe(address)
        }
        
        public enum Block {
            public typealias height = UInt
            public typealias checkpointHeight = UInt
            public typealias startHeight = UInt
            public typealias count = UInt
            
            case header(height, checkpointHeight)
            case headers(startHeight, count, checkpointHeight)
        }
        
        public enum Header {
            public typealias blockHash = String
            
            case get(blockHash)
        }
        
        public enum Headers {
            case getTip
            case subscribe
            case unsubscribe
        }
        
        public enum Transaction {
            public typealias rawTransaction = String
            public typealias transactionHash = String
            public typealias verbose = Bool
            public typealias includeHeader = Bool
            public typealias blockHeight = UInt
            public typealias transactionPosition = UInt
            public typealias includeMerkleProof = Bool
            
            case broadcast(rawTransaction)
            case get(transactionHash, verbose)
            case getConfirmedBlockHash(transactionHash, includeHeader)
            case getHeight(transactionHash)
            case getMerkle(transactionHash)
            case idFromPos(blockHeight, transactionPosition, includeMerkleProof)
            case subscribe(transactionHash)
            case unsubscribe(transactionHash)
            
            case dsProof(DSProof)
            
            public enum DSProof {
                public typealias transactionHash = String
                
                case get(transactionHash)
                case list
                case subscribe(transactionHash)
                case unsubscribe(transactionHash)
            }
        }
        
        public enum UTXO {
            public typealias transactionHash = String
            public typealias outputIndex = UInt16
            
            case getInfo(transactionHash, outputIndex)
        }
    }
    
    public enum Mempool {
        case getFeeHistogram
    }
}

// MARK: - CashTokens
extension Method.Blockchain {
    public struct CashTokens {
        struct JSON: Codable {
            let amount: String
            let category: String
            let nft: NFT?
            
            struct NFT: Codable {
                let capability: Capability
                let commitment: String
                
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

// MARK: - Initialize
extension Method: FulcrumMethodInitializable {}

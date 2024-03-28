import Foundation

enum Method {
    case blockchain(Blockchain)
    case mempool(Mempool)
    
    enum Blockchain {
        typealias numberOfBlocks = Int
        case estimateFee(numberOfBlocks)
        case relayFee
        
        case address(Address)
        case block(Block)
        case header(Header)
        case headers(Headers)
        case transaction(Transaction)
        case utxo(UTXO)
        
        enum Address {
            typealias address = String
            typealias tokenFilter = CashTokens.TokenFilter
            typealias fromHeight = UInt
            typealias toHeight = UInt
            typealias includeUnconfirmed = Bool
            
            case getBalance(address, tokenFilter?)
            case getFirstUse(address)
            case getHistory(address, fromHeight?, toHeight?, includeUnconfirmed)
            case getMempool(address)
            case getScriptHash(address)
            case listUnspent(address, tokenFilter?)
            case subscribe(address)
            case unsubscribe(address)
        }
        
        enum Block {
            typealias height = UInt
            typealias checkpointHeight = UInt
            typealias startHeight = UInt
            typealias count = UInt
            
            case header(height, checkpointHeight)
            case headers(startHeight, count, checkpointHeight)
        }
        
        enum Header {
            typealias blockHash = String
            
            case get(blockHash)
        }
        
        enum Headers {
            case getTip
            case subscribe
            case unsubscribe
        }
        
        enum Transaction {
            typealias rawTransaction = String
            typealias transactionHash = String
            typealias verbose = Bool
            typealias includeHeader = Bool
            typealias blockHeight = UInt
            typealias transactionPosition = UInt
            typealias includeMerkleProof = Bool
            
            case broadcast(rawTransaction)
            case get(transactionHash, verbose)
            case getConfirmedBlockHash(transactionHash, includeHeader)
            case getHeight(transactionHash)
            case getMerkle(transactionHash)
            case idFromPos(blockHeight, transactionPosition, includeMerkleProof)
            case subscribe(transactionHash)
            case unsubscribe(transactionHash)
            
            case dsProof(DSProof)
            
            enum DSProof {
                typealias transactionHash = String
                
                case get(transactionHash)
                case list
                case subscribe(transactionHash)
                case unsubscribe(transactionHash)
            }
        }
        
        enum UTXO {
            typealias transactionHash = String
            typealias outputIndex = UInt16
            
            case getInfo(transactionHash, outputIndex)
        }
    }
    
    enum Mempool {
        case getFeeHistogram
    }
}

// MARK: - CashTokens
extension Method.Blockchain {
    struct CashTokens {
        struct JSON: Codable {
            let amount: String
            let category: String
            let nft: NFT?
            
            struct NFT: Codable {
                let capability: Capability
                let commitment: String
                
                enum Capability: Codable {
                    case none
                    case mutable
                    case minting
                }
            }
        }
        
        enum TokenFilter: String, Codable {
            case include = "include_tokens"
            case exclude = "exclude_tokens"
            case only = "tokens_only"
        }
    }
}

// MARK: - Initialize
extension Method: FulcrumMethodInitializable {}

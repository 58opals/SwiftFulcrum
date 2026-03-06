import Foundation

public extension SwiftFulcrum.RPC {
    enum Method {
    case server(Server)
    case blockchain(Blockchain)
    case mempool(Mempool)
    
    public enum Server {
        case ping
        case version(clientName: String, protocolNegotiation: SwiftFulcrum.Client.Configuration.ProtocolNegotiation.Argument)
        case features
    }
    
    public enum Blockchain {
        case estimateFee(numberOfBlocks: Int)
        case relayFee
        
        case scripthash(ScriptHash)
        case address(Address)
        case block(Block)
        case header(Header)
        case headers(Headers)
        case transaction(Transaction)
        case utxo(UTXO)
        
        public enum ScriptHash {
            case getBalance(scripthash: String, tokenFilter: CashTokens.TokenFilter?)
            case getFirstUse(scripthash: String)
            case getHistory(scripthash: String, fromHeight: UInt?, toHeight: UInt?, shouldIncludeUnconfirmed: Bool)
            case getMempool(scripthash: String)
            case listUnspent(scripthash: String, tokenFilter: CashTokens.TokenFilter?)
            case subscribe(scripthash: String)
            case unsubscribe(scripthash: String)
        }
        
        public enum Address {
            public typealias fromHeight = UInt
            public typealias toHeight = UInt
            public typealias shouldIncludeUnconfirmed = Bool
            
            case getBalance(address: String, tokenFilter: CashTokens.TokenFilter?)
            case getFirstUse(address: String)
            case getHistory(address: String, fromHeight: UInt?, toHeight: UInt?, shouldIncludeUnconfirmed: Bool)
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
            case get(transactionHash: String, isVerbose: Bool)
            case getConfirmedBlockHash(transactionHash: String, shouldIncludeHeader: Bool)
            case getHeight(transactionHash: String)
            case getMerkle(transactionHash: String)
            case idFromPos(blockHeight: UInt, transactionPosition: UInt, shouldIncludeMerkleProof: Bool)
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
        case getInfo
        case getFeeHistogram
    }
    }
}

// MARK: - CashTokens
extension SwiftFulcrum.RPC.Method.Blockchain {
    public struct CashTokens {
        public struct JSON: Codable {
            public let amount: String
            public let category: String
            public let nft: NFT?
            
            public struct NFT: Codable {
                public let capability: Capability
                public let commitment: String
                
                public enum Capability: String, Codable {
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

extension SwiftFulcrum.RPC.Method: Sendable {}
extension SwiftFulcrum.RPC.Method.Server: Sendable {}
extension SwiftFulcrum.RPC.Method.Blockchain: Sendable {}
extension SwiftFulcrum.RPC.Method.Blockchain.ScriptHash: Sendable {}
extension SwiftFulcrum.RPC.Method.Blockchain.Address: Sendable {}
extension SwiftFulcrum.RPC.Method.Blockchain.Block: Sendable {}
extension SwiftFulcrum.RPC.Method.Blockchain.Header: Sendable {}
extension SwiftFulcrum.RPC.Method.Blockchain.Headers: Sendable {}
extension SwiftFulcrum.RPC.Method.Blockchain.Transaction: Sendable {}
extension SwiftFulcrum.RPC.Method.Blockchain.Transaction.DSProof: Sendable {}
extension SwiftFulcrum.RPC.Method.Blockchain.UTXO: Sendable {}
extension SwiftFulcrum.RPC.Method.Blockchain.CashTokens: Sendable {}
extension SwiftFulcrum.RPC.Method.Blockchain.CashTokens.TokenFilter: Sendable {}
extension SwiftFulcrum.RPC.Method.Blockchain.CashTokens.JSON: Sendable {}
extension SwiftFulcrum.RPC.Method.Blockchain.CashTokens.JSON.NFT: Sendable {}
extension SwiftFulcrum.RPC.Method.Blockchain.CashTokens.JSON.NFT.Capability: Sendable {}
extension SwiftFulcrum.RPC.Method.Mempool: Sendable {}

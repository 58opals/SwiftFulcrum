// SwiftFulcrum.RPC.Method.swift

import Foundation

public extension SwiftFulcrum.RPC {
    enum Method {
    case server(ServerModel)
    case blockchain(BlockchainModel)
    case mempool(MempoolModel)
    
    public enum ServerModel {
        case ping
        case version(clientName: String, protocolNegotiation: SwiftFulcrum.Client.Configuration.ProtocolNegotiationModel.Argument)
        case features
    }
    
    public enum BlockchainModel {
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
    
    public enum MempoolModel {
        case getInfo
        case getFeeHistogram
    }
    }
}

// MARK: - CashTokens
extension SwiftFulcrum.RPC.Method.BlockchainModel {
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
extension SwiftFulcrum.RPC.Method.ServerModel: Sendable {}
extension SwiftFulcrum.RPC.Method.BlockchainModel: Sendable {}
extension SwiftFulcrum.RPC.Method.BlockchainModel.ScriptHash: Sendable {}
extension SwiftFulcrum.RPC.Method.BlockchainModel.Address: Sendable {}
extension SwiftFulcrum.RPC.Method.BlockchainModel.Block: Sendable {}
extension SwiftFulcrum.RPC.Method.BlockchainModel.Header: Sendable {}
extension SwiftFulcrum.RPC.Method.BlockchainModel.Headers: Sendable {}
extension SwiftFulcrum.RPC.Method.BlockchainModel.Transaction: Sendable {}
extension SwiftFulcrum.RPC.Method.BlockchainModel.Transaction.DSProof: Sendable {}
extension SwiftFulcrum.RPC.Method.BlockchainModel.UTXO: Sendable {}
extension SwiftFulcrum.RPC.Method.BlockchainModel.CashTokens: Sendable {}
extension SwiftFulcrum.RPC.Method.BlockchainModel.CashTokens.TokenFilter: Sendable {}
extension SwiftFulcrum.RPC.Method.BlockchainModel.CashTokens.JSON: Sendable {}
extension SwiftFulcrum.RPC.Method.BlockchainModel.CashTokens.JSON.NFT: Sendable {}
extension SwiftFulcrum.RPC.Method.BlockchainModel.CashTokens.JSON.NFT.Capability: Sendable {}
extension SwiftFulcrum.RPC.Method.MempoolModel: Sendable {}

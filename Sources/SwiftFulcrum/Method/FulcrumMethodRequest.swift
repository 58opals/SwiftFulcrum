// FulcrumMethodRequest.swift

import Foundation

public enum FulcrumMethodRequest {
    case server(ServerModel)
    case blockchain(BlockchainModel)
    case mempool(MempoolModel)
    
    public enum ServerModel {
        case ping
        case version(clientName: String, protocolNegotiation: FulcrumClient.Configuration.ProtocolNegotiationModel.ArgumentModel)
        case features
    }
    
    public enum BlockchainModel {
        case estimateFee(numberOfBlocks: Int)
        case relayFee
        
        case scripthash(ScriptHashModel)
        case address(AddressModel)
        case block(BlockModel)
        case header(HeaderModel)
        case headers(HeadersModel)
        case transaction(TransactionModel)
        case utxo(UTXOModel)
        
        public enum ScriptHashModel {
            case getBalance(scripthash: String, tokenFilter: CashTokensModel.TokenFilterModel?)
            case getFirstUse(scripthash: String)
            case getHistory(scripthash: String, fromHeight: UInt?, toHeight: UInt?, shouldIncludeUnconfirmed: Bool)
            case getMempool(scripthash: String)
            case listUnspent(scripthash: String, tokenFilter: CashTokensModel.TokenFilterModel?)
            case subscribe(scripthash: String)
            case unsubscribe(scripthash: String)
        }
        
        public enum AddressModel {
            public typealias fromHeight = UInt
            public typealias toHeight = UInt
            public typealias shouldIncludeUnconfirmed = Bool
            
            case getBalance(address: String, tokenFilter: CashTokensModel.TokenFilterModel?)
            case getFirstUse(address: String)
            case getHistory(address: String, fromHeight: UInt?, toHeight: UInt?, shouldIncludeUnconfirmed: Bool)
            case getMempool(address: String)
            case getScriptHash(address: String)
            case listUnspent(address: String, tokenFilter: CashTokensModel.TokenFilterModel?)
            case subscribe(address: String)
            case unsubscribe(address: String)
        }
        
        public enum BlockModel {
            case header(height: UInt, checkpointHeight: UInt? = nil)
            case headers(startHeight: UInt, count: UInt, checkpointHeight: UInt? = nil)
        }
        
        public enum HeaderModel {
            case get(blockHash: String)
        }
        
        public enum HeadersModel {
            case getTip
            case subscribe
            case unsubscribe
        }
        
        public enum TransactionModel {
            case broadcast(rawTransaction: String)
            case get(transactionHash: String, isVerbose: Bool)
            case getConfirmedBlockHash(transactionHash: String, shouldIncludeHeader: Bool)
            case getHeight(transactionHash: String)
            case getMerkle(transactionHash: String)
            case idFromPos(blockHeight: UInt, transactionPosition: UInt, shouldIncludeMerkleProof: Bool)
            case subscribe(transactionHash: String)
            case unsubscribe(transactionHash: String)
            
            case dsProof(DSProofModel)
            
            public enum DSProofModel {
                case get(transactionHash: String)
                case list
                case subscribe(transactionHash: String)
                case unsubscribe(transactionHash: String)
            }
        }
        
        public enum UTXOModel {
            case getInfo(transactionHash: String, outputIndex: UInt16)
        }
    }
    
    public enum MempoolModel {
        case getInfo
        case getFeeHistogram
    }
}

// MARK: - CashTokensModel
extension FulcrumMethodRequest.BlockchainModel {
    public struct CashTokensModel {
        public struct JSONModel: Codable {
            public let amount: String
            public let category: String
            public let nft: NFTModel?
            
            public struct NFTModel: Codable {
                public let capability: CapabilityModel
                public let commitment: String
                
                public enum CapabilityModel: String, Codable {
                    case none
                    case mutable
                    case minting
                }
            }
        }
        
        public enum TokenFilterModel: String, Codable {
            case include = "include_tokens"
            case exclude = "exclude_tokens"
            case only = "tokens_only"
        }
    }
}

extension FulcrumMethodRequest: Sendable {}
extension FulcrumMethodRequest.ServerModel: Sendable {}
extension FulcrumMethodRequest.BlockchainModel: Sendable {}
extension FulcrumMethodRequest.BlockchainModel.ScriptHashModel: Sendable {}
extension FulcrumMethodRequest.BlockchainModel.AddressModel: Sendable {}
extension FulcrumMethodRequest.BlockchainModel.BlockModel: Sendable {}
extension FulcrumMethodRequest.BlockchainModel.HeaderModel: Sendable {}
extension FulcrumMethodRequest.BlockchainModel.HeadersModel: Sendable {}
extension FulcrumMethodRequest.BlockchainModel.TransactionModel: Sendable {}
extension FulcrumMethodRequest.BlockchainModel.TransactionModel.DSProofModel: Sendable {}
extension FulcrumMethodRequest.BlockchainModel.UTXOModel: Sendable {}
extension FulcrumMethodRequest.BlockchainModel.CashTokensModel: Sendable {}
extension FulcrumMethodRequest.BlockchainModel.CashTokensModel.TokenFilterModel: Sendable {}
extension FulcrumMethodRequest.BlockchainModel.CashTokensModel.JSONModel: Sendable {}
extension FulcrumMethodRequest.BlockchainModel.CashTokensModel.JSONModel.NFTModel: Sendable {}
extension FulcrumMethodRequest.BlockchainModel.CashTokensModel.JSONModel.NFTModel.CapabilityModel: Sendable {}
extension FulcrumMethodRequest.MempoolModel: Sendable {}

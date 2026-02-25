// FulcrumMethodRequest~Request.swift

import Foundation

extension FulcrumMethodRequest {
    func createRequest(with uuid: UUID) -> Request {
        switch self {
            // MARK: - ServerModel
        case .server(let server):
            switch server {
            case .ping:
                struct ParametersModel: Encodable {
                    func encode(to encoder: Encoder) throws {
                        _ = encoder.unkeyedContainer()
                    }
                }
                
                return Request(id: uuid,
                               method: self,
                               params: ParametersModel())
                
            case .version(let clientName, let negotiationArgument):
                struct ParametersModel: Encodable {
                    let clientName: String
                    let negotiationArgument: FulcrumClient.Configuration.ProtocolNegotiationModel.ArgumentModel
                    
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.unkeyedContainer()
                        try container.encode(clientName)
                        try container.encode(negotiationArgument)
                    }
                }
                
                return Request(id: uuid,
                               method: self,
                               params: ParametersModel(clientName: clientName,
                                                  negotiationArgument: negotiationArgument))
                
            case .features:
                struct ParametersModel: Encodable {
                    func encode(to encoder: Encoder) throws {
                        _ = encoder.unkeyedContainer()
                    }
                }
                
                return Request(id: uuid,
                               method: self,
                               params: ParametersModel())
            }
            
            // MARK: - BlockchainModel
        case .blockchain(let blockchain):
            switch blockchain {
                
                // MARK: BlockchainModel.estimateFee
            case .estimateFee(let numberOfBlocks):
                struct ParametersModel: Encodable {
                    let numberOfBlocks: Int
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.unkeyedContainer()
                        try container.encode(numberOfBlocks)
                    }
                }
                return Request(id: uuid,
                               method: self,
                               params: ParametersModel(numberOfBlocks: numberOfBlocks))
                
                // MARK: BlockchainModel.relayFee
            case .relayFee:
                struct ParametersModel: Encodable {
                    func encode(to encoder: Encoder) throws {
                        _ = encoder.unkeyedContainer()
                    }
                }
                return Request(id: uuid,
                               method: self,
                               params: ParametersModel())
                
                // MARK: - BlockchainModel.ScriptHashModel
            case .scripthash(let scripthash):
                switch scripthash {
                    
                    // MARK: BlockchainModel.ScriptHashModel.getBalance
                case .getBalance(let scripthash, let tokenFilter):
                    struct ParametersModel: Encodable {
                        let scripthash: String
                        let tokenFilter: FulcrumMethodRequest.BlockchainModel.CashTokensModel.TokenFilterModel?
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(scripthash)
                            if let tokenFilter = tokenFilter { try container.encode(tokenFilter) }
                        }
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel(scripthash: scripthash,
                                                      tokenFilter: tokenFilter))
                    
                    // MARK: BlockchainModel.ScriptHashModel.getFirstUse
                case .getFirstUse(let scripthash):
                    struct ParametersModel: Encodable {
                        let scripthash: String
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(scripthash)
                        }
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel(scripthash: scripthash))
                    
                    // MARK: BlockchainModel.ScriptHashModel.getHistory
                case .getHistory(let scripthash, let fromHeight, let toHeight, let shouldIncludeUnconfirmed):
                    struct ParametersModel: Encodable {
                        let scripthash: String
                        let fromHeight: UInt?
                        let toHeight: UInt?
                        let shouldIncludeUnconfirmed: Bool
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            
                            try container.encode(scripthash)
                            try container.encode(fromHeight ?? 0)
                            if shouldIncludeUnconfirmed { try container.encode(Int(-1)) }
                            else if let toHeight { try container.encode(toHeight) }
                            else { try container.encode(UInt.max) }
                        }
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel(scripthash: scripthash,
                                                      fromHeight: fromHeight,
                                                      toHeight: toHeight,
                                                      shouldIncludeUnconfirmed: shouldIncludeUnconfirmed))
                    
                    // MARK: BlockchainModel.ScriptHashModel.getMempool
                case .getMempool(let scripthash):
                    struct ParametersModel: Encodable {
                        let scripthash: String
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(scripthash)
                        }
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel(scripthash: scripthash))
                    
                    // MARK: BlockchainModel.ScriptHashModel.listUnspent
                case .listUnspent(let scripthash, let tokenFilter):
                    struct ParametersModel: Encodable {
                        let scripthash: String
                        let tokenFilter: FulcrumMethodRequest.BlockchainModel.CashTokensModel.TokenFilterModel?
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(scripthash)
                            if let tokenFilter = tokenFilter { try container.encode(tokenFilter) }
                        }
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel(scripthash: scripthash,
                                                      tokenFilter: tokenFilter))
                    
                    // MARK: BlockchainModel.ScriptHashModel.subscribe
                case .subscribe(let scripthash):
                    struct ParametersModel: Encodable {
                        let scripthash: String
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(scripthash)
                        }
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel(scripthash: scripthash))
                    
                    // MARK: BlockchainModel.ScriptHashModel.unsubscribe
                case .unsubscribe(let scripthash):
                    struct ParametersModel: Encodable {
                        let scripthash: String
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(scripthash)
                        }
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel(scripthash: scripthash))
                }
                
                // MARK: - BlockchainModel.AddressModel
            case .address(let address):
                switch address {
                    
                    // MARK: BlockchainModel.AddressModel.getBalance
                case .getBalance(let address, let tokenFilter):
                    struct ParametersModel: Encodable {
                        let address: String
                        let tokenFilter: FulcrumMethodRequest.BlockchainModel.CashTokensModel.TokenFilterModel?
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(address)
                            if let tokenFilter = tokenFilter { try container.encode(tokenFilter) }
                        }
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel(address: address,
                                                      tokenFilter: tokenFilter))
                    
                    // MARK: BlockchainModel.AddressModel.getFirstUse
                case .getFirstUse(let address):
                    struct ParametersModel: Encodable {
                        let address: String
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(address)
                        }
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel(address: address))
                    
                    // MARK: BlockchainModel.AddressModel.getHistory
                case .getHistory(let address, let fromHeight, let toHeight, let shouldIncludeUnconfirmed):
                    struct ParametersModel: Encodable {
                        let address: String
                        let fromHeight: UInt?
                        let toHeight: UInt?
                        let shouldIncludeUnconfirmed: Bool
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            
                            try container.encode(address)
                            try container.encode(fromHeight ?? 0)
                            if shouldIncludeUnconfirmed { try container.encode(Int(-1)) }
                            else if let toHeight { try container.encode(toHeight) }
                            else { try container.encode(UInt.max) }
                        }
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel(address: address,
                                                      fromHeight: fromHeight,
                                                      toHeight: toHeight,
                                                      shouldIncludeUnconfirmed: shouldIncludeUnconfirmed))
                    
                    // MARK: BlockchainModel.AddressModel.getMempool
                case .getMempool(let address):
                    struct ParametersModel: Encodable {
                        let address: String
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(address)
                        }
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel(address: address))
                    
                    // MARK: BlockchainModel.AddressModel.getScriptHash
                case .getScriptHash(let address):
                    struct ParametersModel: Encodable {
                        let address: String
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(address)
                        }
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel(address: address))
                    
                    // MARK: BlockchainModel.AddressModel.listUnspent
                case .listUnspent(let address, let tokenFilter):
                    struct ParametersModel: Encodable {
                        let address: String
                        let tokenFilter: FulcrumMethodRequest.BlockchainModel.CashTokensModel.TokenFilterModel?
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(address)
                            if let tokenFilter = tokenFilter { try container.encode(tokenFilter) }
                        }
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel(address: address,
                                                      tokenFilter: tokenFilter))
                    
                    // MARK: BlockchainModel.AddressModel.subscribe
                case .subscribe(let address):
                    struct ParametersModel: Encodable {
                        let address: String
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(address)
                        }
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel(address: address))
                    
                    // MARK: BlockchainModel.AddressModel.unsubscribe
                case .unsubscribe(let address):
                    struct ParametersModel: Encodable {
                        let address: String
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(address)
                        }
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel(address: address))
                }
                
                // MARK: - BlockchainModel.BlockModel
            case .block(let block):
                switch block {
                    
                    // MARK: BlockchainModel.BlockModel.header
                case .header(let height, let checkpointHeight):
                    struct ParametersModel: Encodable {
                        let height: UInt
                        let checkpointHeight: UInt
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(height)
                            try container.encode(checkpointHeight)
                        }
                    }
                    let resolvedCheckpointHeight: UInt
                    if let checkpointHeight {
                        resolvedCheckpointHeight = checkpointHeight
                    } else {
                        let (incrementedHeight, didOverflow) = height.addingReportingOverflow(1)
                        resolvedCheckpointHeight = didOverflow ? height : incrementedHeight
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel(height: height,
                                                      checkpointHeight: resolvedCheckpointHeight))
                    
                    // MARK: BlockchainModel.BlockModel.headers
                case .headers(let startHeight, let count, let checkpointHeight):
                    struct ParametersModel: Encodable {
                        let startHeight: UInt
                        let count: UInt
                        let checkpointHeight: UInt
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(startHeight)
                            try container.encode(count)
                            try container.encode(checkpointHeight)
                        }
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel(startHeight: startHeight,
                                                      count: count,
                                                      checkpointHeight: checkpointHeight ?? 0))
                }
                
                // MARK: - BlockchainModel.HeaderModel
            case .header(let header):
                switch header {
                    
                    // MARK: BlockchainModel.HeaderModel.get
                case .get(let blockHash):
                    struct ParametersModel: Encodable {
                        let blockHash: String
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(blockHash)
                        }
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel(blockHash: blockHash))
                }
                
                // MARK: - BlockchainModel.HeadersModel
            case .headers(let headers):
                switch headers {
                    
                    // MARK: BlockchainModel.HeadersModel.getTip
                case .getTip:
                    struct ParametersModel: Encodable {
                        func encode(to encoder: Encoder) throws {
                            _ = encoder.unkeyedContainer()
                        }
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel())
                    
                    // MARK: BlockchainModel.HeadersModel.subscribe
                case .subscribe:
                    struct ParametersModel: Encodable {
                        func encode(to encoder: Encoder) throws {
                            _ = encoder.unkeyedContainer()
                        }
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel())
                    
                    // MARK: BlockchainModel.HeadersModel.unsubscribe
                case .unsubscribe:
                    struct ParametersModel: Encodable {
                        func encode(to encoder: Encoder) throws {
                            _ = encoder.unkeyedContainer()
                        }
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel())
                }
                
                // MARK: - BlockchainModel.TransactionModel
            case .transaction(let transaction):
                switch transaction {
                    
                    // MARK: BlockchainModel.TransactionModel.broadcast
                case .broadcast(let rawTransaction):
                    struct ParametersModel: Encodable {
                        let rawTransaction: String
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(rawTransaction)
                        }
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel(rawTransaction: rawTransaction))
                    
                    // MARK: BlockchainModel.TransactionModel.get
                case .get(let transactionHash, let isVerbose):
                    struct ParametersModel: Encodable {
                        let transactionHash: String
                        let isVerbose: Bool
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(transactionHash)
                            try container.encode(isVerbose)
                        }
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel(transactionHash: transactionHash,
                                                      isVerbose: isVerbose))
                    
                    // MARK: BlockchainModel.TransactionModel.getConfirmedBlockHash
                case .getConfirmedBlockHash(let transactionHash, let shouldIncludeHeader):
                    struct ParametersModel: Encodable {
                        let transactionHash: String
                        let shouldIncludeHeader: Bool
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(transactionHash)
                            try container.encode(shouldIncludeHeader)
                        }
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel(transactionHash: transactionHash,
                                                      shouldIncludeHeader: shouldIncludeHeader))
                    
                    // MARK: BlockchainModel.TransactionModel.getHeight
                case .getHeight(let transactionHash):
                    struct ParametersModel: Encodable {
                        let transactionHash: String
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(transactionHash)
                        }
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel(transactionHash: transactionHash))
                    
                    // MARK: BlockchainModel.TransactionModel.getMerkle
                case .getMerkle(let transactionHash):
                    struct ParametersModel: Encodable {
                        let transactionHash: String
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(transactionHash)
                        }
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel(transactionHash: transactionHash))
                    
                    // MARK: BlockchainModel.TransactionModel.idFromPos
                case .idFromPos(let blockHeight, let transactionPosition, let shouldIncludeMerkleProof):
                    struct ParametersModel: Encodable {
                        let blockHeight: UInt
                        let transactionPosition: UInt
                        let shouldIncludeMerkleProof: Bool
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(blockHeight)
                            try container.encode(transactionPosition)
                            try container.encode(shouldIncludeMerkleProof)
                        }
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel(blockHeight: blockHeight,
                                                      transactionPosition: transactionPosition,
                                                      shouldIncludeMerkleProof: shouldIncludeMerkleProof))
                    
                    // MARK: BlockchainModel.TransactionModel.subscribe
                case .subscribe(let transactionHash):
                    struct ParametersModel: Encodable {
                        let transactionHash: String
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(transactionHash)
                        }
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel(transactionHash: transactionHash))
                    
                    // MARK: BlockchainModel.TransactionModel.unsubscribe
                case .unsubscribe(let transactionHash):
                    struct ParametersModel: Encodable {
                        let transactionHash: String
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(transactionHash)
                        }
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel(transactionHash: transactionHash))
                    
                    // MARK: - BlockchainModel.TransactionModel.DSProofModel
                case .dsProof(let dSProof):
                    switch dSProof {
                        
                        // MARK: BlockchainModel.TransactionModel.DSProofModel.get
                    case .get(let transactionHash):
                        struct ParametersModel: Encodable {
                            let transactionHash: String
                            func encode(to encoder: Encoder) throws {
                                var container = encoder.unkeyedContainer()
                                try container.encode(transactionHash)
                            }
                        }
                        return Request(id: uuid,
                                       method: self,
                                       params: ParametersModel(transactionHash: transactionHash))
                        
                        // MARK: BlockchainModel.TransactionModel.DSProofModel.list
                    case .list:
                        struct ParametersModel: Encodable {
                            func encode(to encoder: Encoder) throws {
                                _ = encoder.unkeyedContainer()
                            }
                        }
                        return Request(id: uuid,
                                       method: self,
                                       params: ParametersModel())
                        
                        // MARK: BlockchainModel.TransactionModel.DSProofModel.subscribe
                    case .subscribe(let transactionHash):
                        struct ParametersModel: Encodable {
                            let transactionHash: String
                            func encode(to encoder: Encoder) throws {
                                var container = encoder.unkeyedContainer()
                                try container.encode(transactionHash)
                            }
                        }
                        return Request(id: uuid,
                                       method: self,
                                       params: ParametersModel(transactionHash: transactionHash))
                        
                        // MARK: BlockchainModel.TransactionModel.DSProofModel.unsubscribe
                    case .unsubscribe(let transactionHash):
                        struct ParametersModel: Encodable {
                            let transactionHash: String
                            func encode(to encoder: Encoder) throws {
                                var container = encoder.unkeyedContainer()
                                try container.encode(transactionHash)
                            }
                        }
                        return Request(id: uuid,
                                       method: self,
                                       params: ParametersModel(transactionHash: transactionHash))
                    }
                }
                
                // MARK: - BlockchainModel.UTXOModel
            case .utxo(let utxo):
                switch utxo {
                    
                    // MARK: BlockchainModel.UTXOModel.getInfo
                case .getInfo(let transactionHash, let outputIndex):
                    struct ParametersModel: Encodable {
                        let transactionHash: String
                        let outputIndex: UInt16
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(transactionHash)
                            try container.encode(outputIndex)
                        }
                    }
                    return Request(id: uuid,
                                   method: self,
                                   params: ParametersModel(transactionHash: transactionHash,
                                                      outputIndex: outputIndex))
                }
            }
            
            // MARK: - MempoolModel
        case .mempool(let mempool):
            switch mempool {
                
                // MARK: MempoolModel.getInfo
            case .getInfo:
                struct ParametersModel: Encodable {
                    func encode(to encoder: Encoder) throws {
                        _ = encoder.unkeyedContainer()
                    }
                }
                return Request(id: uuid,
                               method: self,
                               params: ParametersModel())
                
                // MARK: MempoolModel.getFeeHistogram
            case .getFeeHistogram:
                struct ParametersModel: Encodable {
                    func encode(to encoder: Encoder) throws {
                        _ = encoder.unkeyedContainer()
                    }
                }
                return Request(id: uuid,
                               method: self,
                               params: ParametersModel())
            }
        }
    }
}

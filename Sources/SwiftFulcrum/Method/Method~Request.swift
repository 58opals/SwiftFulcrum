import Foundation

extension Method {
    var request: Request {
        switch self {
        case .blockchain(let blockchain):
            switch blockchain {
                
                // MARK: Blockchain.estimateFee
            case .estimateFee(let numberOfBlocks):
                struct Parameters: Encodable {
                    let numberOfBlocks: Int
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.unkeyedContainer()
                        try container.encode(numberOfBlocks)
                    }
                }
                return Request(method: self,
                               params: Parameters(numberOfBlocks: numberOfBlocks))
                
                // MARK: Blockchain.relayFee
            case .relayFee:
                struct Parameters: Encodable {
                    func encode(to encoder: Encoder) throws {
                        _ = encoder.unkeyedContainer()
                    }
                }
                return Request(method: self,
                               params: Parameters())
                
            case .address(let address):
                switch address {
                    
                    // MARK: Blockchain.Address.getBalance
                case .getBalance(let address, let tokenFilter):
                    struct Parameters: Encodable {
                        let address: String
                        let tokenFilter: Method.Blockchain.CashTokens.TokenFilter?
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(address)
                            if let tokenFilter = tokenFilter { try container.encode(tokenFilter) }
                        }
                    }
                    return Request(method: self,
                                   params: Parameters(address: address,
                                                      tokenFilter: tokenFilter))
                    
                    // MARK: Blockchain.Address.getFirstUse
                case .getFirstUse(let address):
                    struct Parameters: Encodable {
                        let address: String
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(address)
                        }
                    }
                    return Request(method: self,
                                   params: Parameters(address: address))
                    
                    // MARK: Blockchain.Address.getHistory
                case .getHistory(let address, let fromHeight, let toHeight, let includeUnconfirmed):
                    struct Parameters: Encodable {
                        let address: String
                        let fromHeight: UInt?
                        let toHeight: UInt?
                        let includeUnconfirmed: Bool
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(address)
                            //if let fromHeight = fromHeight { try container.encode(fromHeight) }
                            if let fromHeight = fromHeight { try container.encode(fromHeight) } else { try container.encode(Int(0)) }
                            if includeUnconfirmed { try container.encode(Int(-1)) } else if let toHeight = toHeight { try container.encode(toHeight) }
                        }
                    }
                    return Request(method: self,
                                   params: Parameters(address: address,
                                                      fromHeight: fromHeight,
                                                      toHeight: toHeight,
                                                      includeUnconfirmed: includeUnconfirmed))
                    
                    // MARK: Blockchain.Address.getMempool
                case .getMempool(let address):
                    struct Parameters: Encodable {
                        let address: String
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(address)
                        }
                    }
                    return Request(method: self,
                                   params: Parameters(address: address))
                    
                    // MARK: Blockchain.Address.getScriptHash
                case .getScriptHash(let address):
                    struct Parameters: Encodable {
                        let address: String
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(address)
                        }
                    }
                    return Request(method: self,
                                   params: Parameters(address: address))
                    
                    // MARK: Blockchain.Address.listUnspent
                case .listUnspent(let address, let tokenFilter):
                    struct Parameters: Encodable {
                        let address: String
                        let tokenFilter: Method.Blockchain.CashTokens.TokenFilter?
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(address)
                            if let tokenFilter = tokenFilter { try container.encode(tokenFilter) }
                        }
                    }
                    return Request(method: self,
                                   params: Parameters(address: address,
                                                      tokenFilter: tokenFilter))
                    
                    // MARK: Blockchain.Address.subscribe
                case .subscribe(let address):
                    struct Parameters: Encodable {
                        let address: String
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(address)
                        }
                    }
                    return Request(method: self,
                                   params: Parameters(address: address))
                    
                    // MARK: Blockchain.Address.unsubscribe
                case .unsubscribe(let address):
                    struct Parameters: Encodable {
                        let address: String
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(address)
                        }
                    }
                    return Request(method: self,
                                   params: Parameters(address: address))
                }
                
            case .block(let block):
                switch block {
                    
                    // MARK: Blockchain.Block.header
                case .header(let height, let checkpointHeight):
                    struct Parameters: Encodable {
                        let height: UInt
                        let checkpointHeight: UInt
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(height)
                            try container.encode(checkpointHeight)
                        }
                    }
                    return Request(method: self,
                                   params: Parameters(height: height,
                                                      checkpointHeight: checkpointHeight ?? height + 1))
                    
                    // MARK: Blockchain.Block.headers
                case .headers(let startHeight, let count, let checkpointHeight):
                    struct Parameters: Encodable {
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
                    return Request(method: self,
                                   params: Parameters(startHeight: startHeight,
                                                      count: count,
                                                      checkpointHeight: checkpointHeight ?? 0))
                }
                
            case .header(let header):
                switch header {
                    
                    // MARK: Blockchain.Header.get
                case .get(let blockHash):
                    struct Parameters: Encodable {
                        let blockHash: String
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(blockHash)
                        }
                    }
                    return Request(method: self,
                                   params: Parameters(blockHash: blockHash))
                }
            case .headers(let headers):
                switch headers {
                    
                    // MARK: Blockchain.Headers.getTip
                case .getTip:
                    struct Parameters: Encodable {
                        func encode(to encoder: Encoder) throws {
                            _ = encoder.unkeyedContainer()
                        }
                    }
                    return Request(method: self,
                                   params: Parameters())
                    
                    // MARK: Blockchain.Headers.subscribe
                case .subscribe:
                    struct Parameters: Encodable {
                        func encode(to encoder: Encoder) throws {
                            _ = encoder.unkeyedContainer()
                        }
                    }
                    return Request(method: self,
                                   params: Parameters())
                    
                    // MARK: Blockchain.Headers.unsubscribe
                case .unsubscribe:
                    struct Parameters: Encodable {
                        func encode(to encoder: Encoder) throws {
                            _ = encoder.unkeyedContainer()
                        }
                    }
                    return Request(method: self,
                                   params: Parameters())
                }
            case .transaction(let transaction):
                switch transaction {
                    
                    // MARK: Blockchain.Transaction.broadcast
                case .broadcast(let rawTransaction):
                    struct Parameters: Encodable {
                        let rawTransaction: String
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(rawTransaction)
                        }
                    }
                    return Request(method: self,
                                   params: Parameters(rawTransaction: rawTransaction))
                    
                    // MARK: Blockchain.Transaction.get
                case .get(let transactionHash, let verbose):
                    struct Parameters: Encodable {
                        let transactionHash: String
                        let verbose: Bool
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(transactionHash)
                            try container.encode(verbose)
                        }
                    }
                    return Request(method: self,
                                   params: Parameters(transactionHash: transactionHash,
                                                      verbose: verbose))
                    
                    // MARK: Blockchain.Transaction.getConfirmedBlockHash
                case .getConfirmedBlockHash(let transactionHash, let includeHeader):
                    struct Parameters: Encodable {
                        let transactionHash: String
                        let includeHeader: Bool
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(transactionHash)
                            try container.encode(includeHeader)
                        }
                    }
                    return Request(method: self,
                                   params: Parameters(transactionHash: transactionHash,
                                                      includeHeader: includeHeader))
                    
                    // MARK: Blockchain.Transaction.getHeight
                case .getHeight(let transactionHash):
                    struct Parameters: Encodable {
                        let transactionHash: String
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(transactionHash)
                        }
                    }
                    return Request(method: self,
                                   params: Parameters(transactionHash: transactionHash))
                    
                    // MARK: Blockchain.Transaction.getMerkle
                case .getMerkle(let transactionHash):
                    struct Parameters: Encodable {
                        let transactionHash: String
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(transactionHash)
                        }
                    }
                    return Request(method: self,
                                   params: Parameters(transactionHash: transactionHash))
                    
                    // MARK: Blockchain.Transaction.idFromPos
                case .idFromPos(let blockHeight, let transactionPosition, let includeMerkleProof):
                    struct Parameters: Encodable {
                        let blockHeight: UInt
                        let transactionPosition: UInt
                        let includeMerkleProof: Bool
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(blockHeight)
                            try container.encode(transactionPosition)
                            try container.encode(includeMerkleProof)
                        }
                    }
                    return Request(method: self,
                                   params: Parameters(blockHeight: blockHeight,
                                                      transactionPosition: transactionPosition,
                                                      includeMerkleProof: includeMerkleProof))
                    
                    // MARK: Blockchain.Transaction.subscribe
                case .subscribe(let transactionHash):
                    struct Parameters: Encodable {
                        let transactionHash: String
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(transactionHash)
                        }
                    }
                    return Request(method: self,
                                   params: Parameters(transactionHash: transactionHash))
                    
                    // MARK: Blockchain.Transaction.unsubscribe
                case .unsubscribe(let transactionHash):
                    struct Parameters: Encodable {
                        let transactionHash: String
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(transactionHash)
                        }
                    }
                    return Request(method: self,
                                   params: Parameters(transactionHash: transactionHash))
                    
                case .dsProof(let dSProof):
                    switch dSProof {
                        
                        // MARK: Blockchain.Transaction.DSProof.get
                    case .get(let transactionHash):
                        struct Parameters: Encodable {
                            let transactionHash: String
                            func encode(to encoder: Encoder) throws {
                                var container = encoder.unkeyedContainer()
                                try container.encode(transactionHash)
                            }
                        }
                        return Request(method: self,
                                       params: Parameters(transactionHash: transactionHash))
                        
                        // MARK: Blockchain.Transaction.DSProof.list
                    case .list:
                        struct Parameters: Encodable {
                            func encode(to encoder: Encoder) throws {
                                _ = encoder.unkeyedContainer()
                            }
                        }
                        return Request(method: self,
                                       params: Parameters())
                        
                        // MARK: Blockchain.Transaction.DSProof.subscribe
                    case .subscribe(let transactionHash):
                        struct Parameters: Encodable {
                            let transactionHash: String
                            func encode(to encoder: Encoder) throws {
                                var container = encoder.unkeyedContainer()
                                try container.encode(transactionHash)
                            }
                        }
                        return Request(method: self,
                                       params: Parameters(transactionHash: transactionHash))
                        
                        // MARK: Blockchain.Transaction.DSProof.unsubscribe
                    case .unsubscribe(let transactionHash):
                        struct Parameters: Encodable {
                            let transactionHash: String
                            func encode(to encoder: Encoder) throws {
                                var container = encoder.unkeyedContainer()
                                try container.encode(transactionHash)
                            }
                        }
                        return Request(method: self,
                                       params: Parameters(transactionHash: transactionHash))
                    }
                }
                
            case .utxo(let utxo):
                switch utxo {
                    
                    // MARK: Blockchain.UTXO.getInfo
                case .getInfo(let transactionHash, let outputIndex):
                    struct Parameters: Encodable {
                        let transactionHash: String
                        let outputIndex: UInt16
                        func encode(to encoder: Encoder) throws {
                            var container = encoder.unkeyedContainer()
                            try container.encode(transactionHash)
                            try container.encode(outputIndex)
                        }
                    }
                    return Request(method: self,
                                   params: Parameters(transactionHash: transactionHash,
                                                      outputIndex: outputIndex))
                }
            }
        case .mempool(let mempool):
            switch mempool {
                
                // MARK: Mempool.getFeeHistogram
            case .getFeeHistogram:
                struct Parameters: Encodable {
                    func encode(to encoder: Encoder) throws {
                        _ = encoder.unkeyedContainer()
                    }
                }
                return Request(method: self,
                               params: Parameters())
            }
        }
    }
}

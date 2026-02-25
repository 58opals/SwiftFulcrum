// MethodAssortmentModel.swift

struct MethodAssortmentModel {
    let method: FulcrumMethodRequest
    let methodPath: String
    
    func validateMethodAssortment() {
        switch method {
            // MARK: - ServerModel
        case .server(let server):
            switch server {
            case .ping: return
            case .version(_, _): return
            case .features: return
            }
            // MARK: - BlockchainModel
        case .blockchain(let blockchain):
            switch blockchain {
            case .estimateFee(_): return
            case .relayFee: return
                // MARK: - BlockchainModel.ScriptHashModel
            case .scripthash(let scripthash):
                switch scripthash {
                case .getBalance(_, _): return
                case .getFirstUse(_): return
                case .getHistory(_, _, _, _): return
                case .getMempool(_): return
                case .listUnspent(_, _): return
                case .subscribe(_): return
                case .unsubscribe(_): return
                }
                // MARK: - BlockchainModel.AddressModel
            case .address(let address):
                switch address {
                case .getBalance(_, _): return
                case .getFirstUse(_): return
                case .getHistory(_, _, _, _): return
                case .getMempool(_): return
                case .getScriptHash(_): return
                case .listUnspent(_, _): return
                case .subscribe(_): return
                case .unsubscribe(_): return
                }
                // MARK: - BlockchainModel.BlockModel
            case .block(let block):
                switch block {
                case .header(_, _): return
                case .headers(_, _, _): return
                }
                // MARK: - BlockchainModel.HeaderModel
            case .header(let header):
                switch header {
                case .get(_): return
                }
                // MARK: - BlockchainModel.HeadersModel
            case .headers(let headers):
                switch headers {
                case .getTip: return
                case .subscribe: return
                case .unsubscribe: return
                }
                // MARK: - BlockchainModel.TransactionModel
            case .transaction(let transaction):
                switch transaction {
                case .broadcast(_): return
                case .get(_, _): return
                case .getConfirmedBlockHash(_, _): return
                case .getHeight(_): return
                case .getMerkle(_): return
                case .idFromPos(_, _, _): return
                case .subscribe(_): return
                case .unsubscribe(_): return
                    // MARK: - BlockchainModel.TransactionModel.DSProofModel
                case .dsProof(let dSProof):
                    switch dSProof {
                    case .get(_): return
                    case .list: return
                    case .subscribe(_): return
                    case .unsubscribe(_): return
                    }
                }
                // MARK: - BlockchainModel.UTXOModel
            case .utxo(let utxo):
                switch utxo {
                case .getInfo(_, _): return
                }
            }
            // MARK: - MempoolModel
        case .mempool(let mempool):
            switch mempool {
            case .getInfo: return
            case .getFeeHistogram: return
            }
        }
    }
    
    func methodPathAssortment() {
        switch methodPath {
            // MARK: - ServerModel
        case "server.ping": return
        case "server.version": return
        case "server.features": return
            // MARK: - BlockchainModel
        case "blockchain.estimatefee": return
        case "blockchain.relayfee": return
            // MARK: - BlockchainModel.ScriptHashModel
        case "blockchain.scripthash.get_balance": return
        case "blockchain.scripthash.get_first_use": return
        case "blockchain.scripthash.get_history": return
        case "blockchain.scripthash.get_mempool": return
        case "blockchain.scripthash.listunspent": return
        case "blockchain.scripthash.subscribe": return
        case "blockchain.scripthash.unsubscribe": return
            // MARK: - BlockchainModel.AddressModel
        case "blockchain.address.get_balance": return
        case "blockchain.address.get_first_use": return
        case "blockchain.address.get_history": return
        case "blockchain.address.get_mempool": return
        case "blockchain.address.get_scripthash": return
        case "blockchain.address.listunspent": return
        case "blockchain.address.subscribe": return
        case "blockchain.address.unsubscribe": return
            // MARK: - BlockchainModel.BlockModel
        case "blockchain.block.header": return
        case "blockchain.block.headers": return
            // MARK: - BlockchainModel.HeaderModel
        case "blockchain.header.get": return
            // MARK: - BlockchainModel.HeadersModel
        case "blockchain.headers.get_tip": return
        case "blockchain.headers.subscribe": return
        case "blockchain.headers.unsubscribe": return
            // MARK: - BlockchainModel.TransactionModel
        case "blockchain.transaction.broadcast": return
        case "blockchain.transaction.get": return
        case "blockchain.transaction.get_confirmed_blockhash": return
        case "blockchain.transaction.get_height": return
        case "blockchain.transaction.get_merkle": return
        case "blockchain.transaction.id_from_pos": return
        case "blockchain.transaction.subscribe": return
        case "blockchain.transaction.unsubscribe": return
            // MARK: - BlockchainModel.TransactionModel.DSProofModel
        case "blockchain.transaction.dsproof.get": return
        case "blockchain.transaction.dsproof.list": return
        case "blockchain.transaction.dsproof.subscribe": return
        case "blockchain.transaction.dsproof.unsubscribe": return
            // MARK: - BlockchainModel.UTXOModel
        case "blockchain.utxo.get_info": return
            // MARK: - MempoolModel
        case "mempool.get_info": return
        case "mempool.get_fee_histogram": return
            
        default: fatalError()
        }
    }
}

extension MethodAssortmentModel {
    static var sampleMethods: [FulcrumMethodRequest] {
        guard let minimumVersion = ProtocolVersionModel(string: "1.4"),
              let maximumVersion = ProtocolVersionModel(string: "1.6.0"),
              let versionRange = ProtocolVersionModel.RangeModel(min: minimumVersion, max: maximumVersion) else {
            preconditionFailure("Sample protocol versions must be valid")
        }
        
        return [
            // ServerModel
            .server(.ping),
            .server(.version(clientName: "Sample Client",
                             protocolNegotiation: .init(range: versionRange))),
            .server(.features),
            
            // BlockchainModel
            .blockchain(
                .estimateFee(numberOfBlocks: 6)),
            .blockchain(
                .relayFee),
            
            // BlockchainModel.ScriptHashModel
            .blockchain(
                .scripthash(
                    .getBalance(scripthash: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
                                tokenFilter: .include))),
            .blockchain(
                .scripthash(
                    .getFirstUse(scripthash: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"))),
            .blockchain(
                .scripthash(
                    .getHistory(scripthash: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
                                fromHeight: nil,
                                toHeight: nil,
                                shouldIncludeUnconfirmed: true))),
            .blockchain(
                .scripthash(
                    .getMempool(scripthash: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"))),
            .blockchain(
                .scripthash(
                    .listUnspent(scripthash: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
                                 tokenFilter: .include))),
            .blockchain(
                .scripthash(
                    .subscribe(scripthash: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"))),
            .blockchain(
                .scripthash(
                    .unsubscribe(scripthash: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"))),
            
            
            // BlockchainModel.AddressModel
            .blockchain(
                .address(
                    .getBalance(address: "qrmydkpmlgvxrafjv7rpdm4unlcdfnljmqss98ytuq",
                                tokenFilter: .include))),
            .blockchain(
                .address(
                    .getFirstUse(address: "qrmydkpmlgvxrafjv7rpdm4unlcdfnljmqss98ytuq"))),
            .blockchain(
                .address(
                    .getHistory(address: "qrmydkpmlgvxrafjv7rpdm4unlcdfnljmqss98ytuq",
                                fromHeight: nil,
                                toHeight: nil,
                                shouldIncludeUnconfirmed: true))),
            .blockchain(
                .address(
                    .getMempool(address: "qrmydkpmlgvxrafjv7rpdm4unlcdfnljmqss98ytuq"))),
            .blockchain(
                .address(
                    .getScriptHash(address: "qrmydkpmlgvxrafjv7rpdm4unlcdfnljmqss98ytuq"))),
            .blockchain(
                .address(
                    .listUnspent(address: "qrmydkpmlgvxrafjv7rpdm4unlcdfnljmqss98ytuq",
                                 tokenFilter: .include))),
            .blockchain(
                .address(
                    .subscribe(address: "qrmydkpmlgvxrafjv7rpdm4unlcdfnljmqss98ytuq"))),
            .blockchain(
                .address(
                    .unsubscribe(address: "qrmydkpmlgvxrafjv7rpdm4unlcdfnljmqss98ytuq"))),
            
            // BlockchainModel.BlockModel
            .blockchain(
                .block(
                    .header(height: 1,
                            checkpointHeight: 0))),
            .blockchain(
                .block(
                    .headers(startHeight: 1,
                             count: 10,
                             checkpointHeight: 0))),
            
            // BlockchainModel.HeaderModel
            .blockchain(
                .header(
                    .get(blockHash: "0000000000000000029c2784e7453617ea6d8e73cbc91b293d06cf41cf3a5286"))),
            
            // BlockchainModel.HeadersModel
            .blockchain(
                .headers(
                    .getTip)),
            .blockchain(
                .headers(
                    .subscribe)),
            .blockchain(
                .headers(
                    .unsubscribe)),
            
            // BlockchainModel.TransactionModel
            .blockchain(
                .transaction(
                    .broadcast(rawTransaction: "rawTx"))),
            .blockchain(
                .transaction(
                    .get(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1",
                         isVerbose: true))),
            .blockchain(
                .transaction(
                    .getConfirmedBlockHash(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1",
                                           shouldIncludeHeader: true))),
            .blockchain(
                .transaction(
                    .getHeight(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1"))),
            .blockchain(
                .transaction(
                    .getMerkle(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1"))),
            .blockchain(
                .transaction(
                    .idFromPos(blockHeight: 1,
                               transactionPosition: 0,
                               shouldIncludeMerkleProof: true))),
            .blockchain(
                .transaction(
                    .subscribe(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1"))),
            .blockchain(
                .transaction(
                    .unsubscribe(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1"))),
            
            // BlockchainModel.TransactionModel.DSProofModel
            .blockchain(
                .transaction(
                    .dsProof(
                        .get(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1")))),
            .blockchain(
                .transaction(
                    .dsProof(
                        .list))),
            .blockchain(
                .transaction(
                    .dsProof(
                        .subscribe(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1")))),
            .blockchain(
                .transaction(
                    .dsProof(
                        .unsubscribe(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1")))),
            
            // BlockchainModel.UTXOModel
            .blockchain(
                .utxo(
                    .getInfo(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1",
                             outputIndex: 0))),
            
            // MempoolModel
            .mempool(.getInfo),
            .mempool(.getFeeHistogram)
        ]
    }
}

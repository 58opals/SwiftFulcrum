// Method(assortment).swift

struct MethodAssortment {
    let method: Method
    let methodPath: String
    
    func methodAssortment() {
        switch method {
            // MARK: - Blockchain
        case .blockchain(let blockchain):
            switch blockchain {
            case .estimateFee(_): return
            case .relayFee: return
                // MARK: - Blockchain.ScriptHash
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
                // MARK: - Blockchain.Address
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
                // MARK: - Blockchain.Block
            case .block(let block):
                switch block {
                case .header(_, _): return
                case .headers(_, _, _): return
                }
                // MARK: - Blockchain.Header
            case .header(let header):
                switch header {
                case .get(_): return
                }
                // MARK: - Blockchain.Headers
            case .headers(let headers):
                switch headers {
                case .getTip: return
                case .subscribe: return
                case .unsubscribe: return
                }
                // MARK: - Blockchain.Transaction
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
                    // MARK: - Blockchain.Transaction.DSProof
                case .dsProof(let dSProof):
                    switch dSProof {
                    case .get(_): return
                    case .list: return
                    case .subscribe(_): return
                    case .unsubscribe(_): return
                    }
                }
                // MARK: - Blockchain.UTXO
            case .utxo(let utxo):
                switch utxo {
                case .getInfo(_, _): return
                }
            }
            // MARK: - Mempool
        case .mempool(let mempool):
            switch mempool {
            case .getFeeHistogram: return
            }
        }
    }
    
    func methodPathAssortment() {
        switch methodPath {
            // MARK: - Blockchain
        case "blockchain.estimatefee": return
        case "blockchain.relayfee": return
            // MARK: - Blockchain.ScriptHash
        case "blockchain.scripthash.get_balance": return
        case "blockchain.scripthash.get_first_use": return
        case "blockchain.scripthash.get_history": return
        case "blockchain.scripthash.get_mempool": return
        case "blockchain.scripthash.listunspent": return
        case "blockchain.scripthash.subscribe": return
        case "blockchain.scripthash.unsubscribe": return
            // MARK: - Blockchain.Address
        case "blockchain.address.get_balance": return
        case "blockchain.address.get_first_use": return
        case "blockchain.address.get_history": return
        case "blockchain.address.get_mempool": return
        case "blockchain.address.get_scripthash": return
        case "blockchain.address.listunspent": return
        case "blockchain.address.subscribe": return
        case "blockchain.address.unsubscribe": return
            // MARK: - Blockchain.Block
        case "blockchain.block.header": return
        case "blockchain.block.headers": return
            // MARK: - Blockchain.Header
        case "blockchain.header.get": return
            // MARK: - Blockchain.Headers
        case "blockchain.headers.get_tip": return
        case "blockchain.headers.subscribe": return
        case "blockchain.headers.unsubscribe": return
            // MARK: - Blockchain.Transaction
        case "blockchain.transaction.broadcast": return
        case "blockchain.transaction.get": return
        case "blockchain.transaction.get_confirmed_blockhash": return
        case "blockchain.transaction.get_height": return
        case "blockchain.transaction.get_merkle": return
        case "blockchain.transaction.id_from_pos": return
        case "blockchain.transaction.subscribe": return
        case "blockchain.transaction.unsubscribe": return
            // MARK: - Blockchain.Transaction.DSProof
        case "blockchain.transaction.dsproof.get": return
        case "blockchain.transaction.dsproof.list": return
        case "blockchain.transaction.dsproof.subscribe": return
        case "blockchain.transaction.dsproof.unsubscribe": return
            // MARK: - Blockchain.UTXO
        case "blockchain.utxo.get_info": return
            // MARK: - Mempool
        case "mempool.get_fee_histogram": return
            
        default: fatalError()
        }
    }
}

extension MethodAssortment {
    static var sampleMethods: [Method] {
        return [
            // Blockchain
            .blockchain(
                .estimateFee(numberOfBlocks: 6)),
            .blockchain(
                .relayFee),
            
            // Blockchain.ScriptHash
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
                                includeUnconfirmed: true))),
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
            
            
            // Blockchain.Address
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
                                includeUnconfirmed: true))),
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
            
            // Blockchain.Block
            .blockchain(
                .block(
                    .header(height: 1,
                            checkpointHeight: 0))),
            .blockchain(
                .block(
                    .headers(startHeight: 1,
                             count: 10,
                             checkpointHeight: 0))),
            
            // Blockchain.Header
            .blockchain(
                .header(
                    .get(blockHash: "0000000000000000029c2784e7453617ea6d8e73cbc91b293d06cf41cf3a5286"))),
            
            // Blockchain.Headers
            .blockchain(
                .headers(
                    .getTip)),
            .blockchain(
                .headers(
                    .subscribe)),
            .blockchain(
                .headers(
                    .unsubscribe)),
            
            // Blockchain.Transaction
            .blockchain(
                .transaction(
                    .broadcast(rawTransaction: "rawTx"))),
            .blockchain(
                .transaction(
                    .get(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1",
                         verbose: true))),
            .blockchain(
                .transaction(
                    .getConfirmedBlockHash(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1",
                                           includeHeader: true))),
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
                               includeMerkleProof: true))),
            .blockchain(
                .transaction(
                    .subscribe(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1"))),
            .blockchain(
                .transaction(
                    .unsubscribe(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1"))),
            
            // Blockchain.Transaction.DSProof
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
            
            // Blockchain.UTXO
            .blockchain(
                .utxo(
                    .getInfo(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1",
                             outputIndex: 0))),
            
            // Mempool
            .mempool(.getFeeHistogram)
        ]
    }
}

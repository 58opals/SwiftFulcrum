// MethodAssortmentModel.swift

struct MethodAssortmentModel {
    let method: SwiftFulcrum.RPC.Method
    let methodPath: String
    
    func validateMethodAssortment() {
        switch method {
            // MARK: - Server
        case .server(let server):
            switch server {
            case .ping: return
            case .version(_, _): return
            case .features: return
            }
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
            case .getInfo: return
            case .getFeeHistogram: return
            }
        }
    }
    
    func methodPathAssortment() {
        switch methodPath {
            // MARK: - Server
        case "server.ping": return
        case "server.version": return
        case "server.features": return
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
        case "mempool.get_info": return
        case "mempool.get_fee_histogram": return
            
        default: fatalError()
        }
    }
}

extension MethodAssortmentModel {
}

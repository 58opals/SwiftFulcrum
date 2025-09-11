// Method~Path.swift

import Foundation

extension Method { var path: String {
    switch self {
    case .blockchain(let blockchainPath): return "blockchain.\(blockchainPath.path)"
    case .mempool(let mempoolPath): return "mempool.\(mempoolPath.path)"
    }}}

extension Method.Blockchain { var path: String {
    switch self {
    case .scripthash(let scripthashPath): return "scripthash.\(scripthashPath.path)"
    case .address(let addressPath): return "address.\(addressPath.path)"
    case .block(let blockPath): return "block.\(blockPath.path)"
    case .header(let headerPath): return "header.\(headerPath.path)"
    case .headers(let headersPath): return "headers.\(headersPath.path)"
    case .transaction(let transactionPath): return "transaction.\(transactionPath.path)"
    case .utxo(let utxoPath): return "utxo.\(utxoPath.path)"
        
    case .estimateFee: return "estimatefee"
    case .relayFee: return "relayfee"
    }}}

extension Method.Blockchain.ScriptHash { var path: String {
    switch self {
    case .getBalance: return "get_balance"
    case .getFirstUse: return "get_first_use"
    case .getHistory: return "get_history"
    case .getMempool: return "get_mempool"
    case .listUnspent: return "listunspent"
    case .subscribe: return "subscribe"
    case .unsubscribe: return "unsubscribe"
    }}}

extension Method.Blockchain.Address { var path: String {
    switch self {
    case .getBalance: return "get_balance"
    case .getFirstUse: return "get_first_use"
    case .getHistory: return "get_history"
    case .getMempool: return "get_mempool"
    case .getScriptHash: return "get_scripthash"
    case .listUnspent: return "listunspent"
    case .subscribe: return "subscribe"
    case .unsubscribe: return "unsubscribe"
    }}}

extension Method.Blockchain.Block { var path: String {
    switch self {
    case .header: return "header"
    case .headers: return "headers"
    }}}

extension Method.Blockchain.Header { var path: String {
    switch self {
    case .get: return "get"
    }}}

extension Method.Blockchain.Headers { var path: String {
    switch self {
    case .getTip: return "get_tip"
    case .subscribe: return "subscribe"
    case .unsubscribe: return "unsubscribe"
    }}}

extension Method.Blockchain.Transaction { var path: String {
    switch self {
    case .dsProof(let dsProofPath): return "dsproof.\(dsProofPath.path)"
        
    case .broadcast: return "broadcast"
    case .get: return "get"
    case .getConfirmedBlockHash: return "get_confirmed_blockhash"
    case .getHeight: return "get_height"
    case .getMerkle: return "get_merkle"
    case .idFromPos: return "id_from_pos"
    case .subscribe: return "subscribe"
    case .unsubscribe: return "unsubscribe"
    }}}

extension Method.Blockchain.Transaction.DSProof { var path: String {
    switch self {
    case .get: return "get"
    case .list: return "list"
    case .subscribe: return "subscribe"
    case .unsubscribe: return "unsubscribe"
    }}}

extension Method.Blockchain.UTXO { var path: String {
    switch self {
    case .getInfo: return "get_info"
    }}}

extension Method.Mempool { var path: String {
    switch self {
    case .getFeeHistogram: return "get_fee_histogram"
    }}}

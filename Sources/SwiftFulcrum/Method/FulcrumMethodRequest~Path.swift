// FulcrumMethodRequest~Path.swift

import Foundation

extension FulcrumMethodRequest { var path: String {
    switch self {
    case .server(let serverPath): return "server.\(serverPath.path)"
    case .blockchain(let blockchainPath): return "blockchain.\(blockchainPath.path)"
    case .mempool(let mempoolPath): return "mempool.\(mempoolPath.path)"
    }}}

extension FulcrumMethodRequest.ServerModel { var path: String {
    switch self {
    case .ping: return "ping"
    case .version: return "version"
    case .features: return "features"
    }}}

extension FulcrumMethodRequest.BlockchainModel { var path: String {
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

extension FulcrumMethodRequest.BlockchainModel.ScriptHashModel { var path: String {
    switch self {
    case .getBalance: return "get_balance"
    case .getFirstUse: return "get_first_use"
    case .getHistory: return "get_history"
    case .getMempool: return "get_mempool"
    case .listUnspent: return "listunspent"
    case .subscribe: return "subscribe"
    case .unsubscribe: return "unsubscribe"
    }}}

extension FulcrumMethodRequest.BlockchainModel.AddressModel { var path: String {
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

extension FulcrumMethodRequest.BlockchainModel.BlockModel { var path: String {
    switch self {
    case .header: return "header"
    case .headers: return "headers"
    }}}

extension FulcrumMethodRequest.BlockchainModel.HeaderModel { var path: String {
    switch self {
    case .get: return "get"
    }}}

extension FulcrumMethodRequest.BlockchainModel.HeadersModel { var path: String {
    switch self {
    case .getTip: return "get_tip"
    case .subscribe: return "subscribe"
    case .unsubscribe: return "unsubscribe"
    }}}

extension FulcrumMethodRequest.BlockchainModel.TransactionModel { var path: String {
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

extension FulcrumMethodRequest.BlockchainModel.TransactionModel.DSProofModel { var path: String {
    switch self {
    case .get: return "get"
    case .list: return "list"
    case .subscribe: return "subscribe"
    case .unsubscribe: return "unsubscribe"
    }}}

extension FulcrumMethodRequest.BlockchainModel.UTXOModel { var path: String {
    switch self {
    case .getInfo: return "get_info"
    }}}

extension FulcrumMethodRequest.MempoolModel { var path: String {
    switch self {
    case .getInfo: return "get_info"
    case .getFeeHistogram: return "get_fee_histogram"
    }}}

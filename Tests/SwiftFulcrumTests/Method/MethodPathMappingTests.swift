import Foundation
import Testing
@testable import SwiftFulcrum

@Suite("Method ↔︎ path mapping")
struct MethodPathMappingTests {
    
    @Test
    func all_paths_match_expected() {
        let addr = "qrmydkpmlgvxrafjv7rpdm4unlcdfnljmqss98ytuq"
        let txid = "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1"
        let blockHash = "0000000000000000029c2784e7453617ea6d8e73cbc91b293d06cf41cf3a5286"
        
        let cases: [(SwiftFulcrum.Method, String)] = [
            // blockchain.*
            (.blockchain(.estimateFee(numberOfBlocks: 6)), "blockchain.estimatefee"),
            (.blockchain(.relayFee), "blockchain.relayfee"),
            
            // blockchain.address.*
            (.blockchain(.address(.getBalance(address: addr, tokenFilter: .include))), "blockchain.address.get_balance"),
            (.blockchain(.address(.getFirstUse(address: addr))), "blockchain.address.get_first_use"),
            (.blockchain(.address(.getHistory(address: addr, fromHeight: 1, toHeight: 100, includeUnconfirmed: true))), "blockchain.address.get_history"),
            (.blockchain(.address(.getMempool(address: addr))), "blockchain.address.get_mempool"),
            (.blockchain(.address(.getScriptHash(address: addr))), "blockchain.address.get_scripthash"),
            (.blockchain(.address(.listUnspent(address: addr, tokenFilter: .include))), "blockchain.address.listunspent"),
            (.blockchain(.address(.subscribe(address: addr))), "blockchain.address.subscribe"),
            (.blockchain(.address(.unsubscribe(address: addr))), "blockchain.address.unsubscribe"),
            
            // blockchain.block.*
            (.blockchain(.block(.header(height: 1, checkpointHeight: nil))), "blockchain.block.header"),
            (.blockchain(.block(.headers(startHeight: 1, count: 10, checkpointHeight: nil))), "blockchain.block.headers"),
            
            // blockchain.header.*
            (.blockchain(.header(.get(blockHash: blockHash))), "blockchain.header.get"),
            
            // blockchain.headers.*
            (.blockchain(.headers(.getTip)), "blockchain.headers.get_tip"),
            (.blockchain(.headers(.subscribe)), "blockchain.headers.subscribe"),
            (.blockchain(.headers(.unsubscribe)), "blockchain.headers.unsubscribe"),
            
            // blockchain.transaction.*
            (.blockchain(.transaction(.broadcast(rawTransaction: "00"))), "blockchain.transaction.broadcast"),
            (.blockchain(.transaction(.get(transactionHash: txid, verbose: true))), "blockchain.transaction.get"),
            (.blockchain(.transaction(.getConfirmedBlockHash(transactionHash: txid, includeHeader: true))), "blockchain.transaction.get_confirmed_blockhash"),
            (.blockchain(.transaction(.getHeight(transactionHash: txid))), "blockchain.transaction.get_height"),
            (.blockchain(.transaction(.getMerkle(transactionHash: txid))), "blockchain.transaction.get_merkle"),
            (.blockchain(.transaction(.idFromPos(blockHeight: 1, transactionPosition: 0, includeMerkleProof: true))), "blockchain.transaction.id_from_pos"),
            (.blockchain(.transaction(.subscribe(transactionHash: txid))), "blockchain.transaction.subscribe"),
            (.blockchain(.transaction(.unsubscribe(transactionHash: txid))), "blockchain.transaction.unsubscribe"),
            
            // blockchain.transaction.dsproof.*
            (.blockchain(.transaction(.dsProof(.get(transactionHash: txid)))), "blockchain.transaction.dsproof.get"),
            (.blockchain(.transaction(.dsProof(.list))), "blockchain.transaction.dsproof.list"),
            (.blockchain(.transaction(.dsProof(.subscribe(transactionHash: txid)))), "blockchain.transaction.dsproof.subscribe"),
            (.blockchain(.transaction(.dsProof(.unsubscribe(transactionHash: txid)))), "blockchain.transaction.dsproof.unsubscribe"),
            
            // blockchain.utxo.*
            (.blockchain(.utxo(.getInfo(transactionHash: txid, outputIndex: 0))), "blockchain.utxo.get_info"),
            
            // mempool.*
            (.mempool(.getFeeHistogram), "mempool.get_fee_histogram"),
        ]
        
        for (method, expected) in cases {
            #expect(method.path == expected)
        }
    }
}

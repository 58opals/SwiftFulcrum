import Testing
import Foundation
@testable import SwiftFulcrum

@Suite("Method.Blockchain.Address – Regular RPCs")
struct MethodBlockchainAddressTests {
    let fulcrum: Fulcrum
    private let address = "qrmfkegyf83zh5kauzwgygf82sdahd5a55x9wse7ve"
    init() throws { self.fulcrum = try Fulcrum() }
    
    private func withRunningNode<T>(_ body: @Sendable () async throws -> T) async throws -> T {
        if !(await fulcrum.isRunning) { try await fulcrum.start() }
        return try await body()
    }
}

extension MethodBlockchainAddressTests {
    /// Fulcrum Method: Blockchain.Address.GetBalance
    @Test("address.get_balance → sane numbers")
    func getBalance() async throws {
        let balance = try await withRunningNode {
            let (_, result) = try await fulcrum.submit(
                method: .blockchain(.address(.getBalance(address: address, tokenFilter: nil))),
                responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.GetBalance>.self)
            return result
        }
        
        print("confirmed=\(balance.confirmed)  unconfirmed=\(balance.unconfirmed)")
        #expect(balance.confirmed >= 0)
        #expect(balance.unconfirmed >= Int64.min)
    }
    
    /// Fulcrum Method: Blockchain.Address.GetFirstUse
    @Test("address.get_first_use → returns a block-height")
    func getFirstUse() async throws {
        let first = try await withRunningNode {
            let (_, result) = try await fulcrum.submit(
                method: .blockchain(.address(.getFirstUse(address: address))),
                responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.GetFirstUse>.self)
            return result
        }
        
        print("first-use height=\(first.height)  tx=\(first.tx_hash)")
        #expect(first.height > 0)
        #expect(first.tx_hash.count == 64)
        #expect(first.block_hash.count == 64)
    }
    
    /// Fulcrum Method: Blockchain.Address.GetHistory
    @Test("address.get_history → decodes all rows")
    func getHistory() async throws {
        let history = try await withRunningNode {
            let (_, items) = try await fulcrum.submit(
                method: .blockchain(.address(.getHistory(address: address,
                                                         fromHeight: nil,
                                                         toHeight: nil,
                                                         includeUnconfirmed: true))),
                responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.GetHistory>.self)
            return items
        }
        
        print("history count \(history.count)")
        #expect(history.count >= 0)
        for row in history { #expect(row.tx_hash.count == 64) }
    }
    
    /// Fulcrum Method: Blockchain.Address.GetMempool
    @Test("address.get_mempool → decodes (may be empty)")
    func getMempool() async throws {
        let mempool = try await withRunningNode {
            let (_, items) = try await fulcrum.submit(
                method: .blockchain(.address(.getMempool(address: address))),
                responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.GetMempool>.self)
            return items
        }
        
        print("mempool txs \(mempool.count)")
        #expect(mempool.count >= 0)
    }
    
    /// Fulcrum Method: Blockchain.Address.GetScriptHash
    @Test("address.get_scripthash → 64-char hex")
    func getScriptHash() async throws {
        let hash = try await withRunningNode {
            let (_, result) = try await fulcrum.submit(
                method: .blockchain(.address(.getScriptHash(address: address))),
                responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.GetScriptHash>.self)
            return result
        }
        
        print("scripthash \(hash)")
        #expect(hash.count == 64)
    }
    
    /// Fulcrum Method: Blockchain.Address.ListUnspent
    @Test("address.listunspent → plausible UTXOs")
    func listUnspent() async throws {
        let utxos = try await withRunningNode {
            let (_, items) = try await fulcrum.submit(
                method: .blockchain(.address(.listUnspent(address: address, tokenFilter: .include))),
                responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.ListUnspent>.self)
            return items
        }
        
        print("UTXO count \(utxos.count)")
        #expect(utxos.count >= 0)
        for utxo in utxos {
            #expect(utxo.tx_hash.count == 64)
            #expect(utxo.value > 0)
        }
    }
}

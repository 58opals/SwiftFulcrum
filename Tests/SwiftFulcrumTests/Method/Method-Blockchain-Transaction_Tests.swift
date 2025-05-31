import Testing
import Foundation
@testable import SwiftFulcrum

@Suite("Method.Blockchain.Transaction – Regular RPCs")
struct MethodBlockchainTransactionTests {
    let fulcrum: Fulcrum
    private let sampleTxID = "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1"
    init() throws { fulcrum = try Fulcrum() }
    
    private func withRunningNode<T>(_ body: @Sendable () async throws -> T) async throws -> T {
        if !(await fulcrum.isRunning) { try await fulcrum.start() }
        return try await body()
    }
}
/*
extension MethodBlockchainTransactionTests {
    /// Fulcrum Method: Blockchain.Transaction.Broadcast
    @Test("transaction.broadcast → fails for malformed raw-tx")
    func broadcastRejectsGarbage() async throws {
        await #expect(throws: Swift.Error.self) {
            try await withRunningNode {
                _ = try await fulcrum.submit(
                    method: .blockchain(.transaction(.broadcast(
                        rawTransaction: "DEADBEEF"))),
                    responseType: Response.Result.Blockchain.Transaction.Broadcast.self)
            }
        }
    }
    
    /// Fulcrum Method: Blockchain.Transaction.Get
    @Test("transaction.get → decodes basic fields")
    func getTransaction() async throws {
        let tx = try await withRunningNode {
            let (_, tx) = try await fulcrum.submit(
                method: .blockchain(.transaction(.get(
                    transactionHash: sampleTxID,
                    verbose: true))),
                responseType: Response.Result.Blockchain.Transaction.Get.self)
            return tx
        }
        
        print("txid: \(tx.transactionID)  size: \(tx.size) bytes")
        #expect(tx.transactionID == sampleTxID)
        #expect(tx.size > 0)
        #expect(tx.inputs.count > 0)
        #expect(tx.outputs.count > 0)
    }
    
    /// Fulcrum Method: Blockchain.Transaction.GetConfirmedBlockHash
    @Test("transaction.get_confirmed_blockhash → has height + hash")
    func confirmedBlockHash() async throws {
        let infoWithoutHeader = try await withRunningNode {
            let (_, info) = try await fulcrum.submit(
                method: .blockchain(.transaction(.getConfirmedBlockHash(
                    transactionHash: sampleTxID,
                    includeHeader: false))),
                responseType: Response.Result.Blockchain.Transaction.GetConfirmedBlockHash.self)
            return info
        }
        
        print("block hash: \(infoWithoutHeader.blockHash)  height: \(infoWithoutHeader.blockHeight)")
        #expect(infoWithoutHeader.blockHash.count == 64)
        #expect(infoWithoutHeader.blockHeight > 0)
    }
    
    /// Fulcrum Method: Blockchain.Transaction.GetHeight
    @Test("transaction.get_height → positive height")
    func getHeight() async throws {
        let height: UInt = try await withRunningNode {
            let (_, h) = try await fulcrum.submit(
                method: .blockchain(.transaction(.getHeight(
                    transactionHash: sampleTxID))),
                responseType: Response.Result.Blockchain.Transaction.GetHeight.self)
            return h.height
        }
        
        print("height: \(height)")
        #expect(height > 0)
    }
    
    /// Fulcrum Method: Blockchain.Transaction.GetMerkle
    @Test("transaction.get_merkle → returns proof branch + position")
    func getMerkle() async throws {
        let merkle = try await withRunningNode {
            let (_, m) = try await fulcrum.submit(
                method: .blockchain(.transaction(.getMerkle(
                    transactionHash: sampleTxID))),
                responseType: Response.Result.Blockchain.Transaction.GetMerkle.self)
            return m
        }
        
        print("merkle branch length: \(merkle.merkle.count)")
        #expect(merkle.blockHeight > 0)
        #expect(merkle.merkle.count > 0)
    }
    
    /// Fulcrum Method: Blockchain.Transaction.IDFromPos
    @Test("transaction.id_from_pos → round-trip txid")
    func idFromPos() async throws {
        // First, discover (height, pos) from get_merkle so the test is data-driven.
        let (height, pos) = try await withRunningNode { () async throws -> (UInt, UInt) in
            let (_, m) = try await fulcrum.submit(
                method: .blockchain(.transaction(.getMerkle(
                    transactionHash: sampleTxID))),
                responseType: Response.Result.Blockchain.Transaction.GetMerkle.self)
            return (m.blockHeight, m.position)
        }
        
        let roundTrip = try await withRunningNode {
            let (_, r) = try await fulcrum.submit(
                method: .blockchain(.transaction(.idFromPos(
                    blockHeight: height,
                    transactionPosition: pos,
                    includeMerkleProof: true))),
                responseType: Response.Result.Blockchain.Transaction.IDFromPos.self)
            return r
        }
        
        print("round-trip tx_hash: \(roundTrip.transactionHash)")
        #expect(roundTrip.transactionHash == sampleTxID)
    }
}
*/

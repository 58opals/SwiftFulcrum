import Testing
import Foundation
@testable import SwiftFulcrum

@Suite("Method.Blockchain.Transaction – Regular RPCs")
struct MethodBlockchainTransactionTests {
    let fulcrum: Fulcrum
    private let sampleTxID = "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1"
    init() async throws { fulcrum = try await Fulcrum() }
    
    private func withRunningNode<T>(_ body: @Sendable () async throws -> T) async throws -> T {
        if !(await fulcrum.isRunning) { try await fulcrum.start() }
        return try await body()
    }
}

extension MethodBlockchainTransactionTests {
    /// Fulcrum Method: Blockchain.Transaction.Broadcast
    @Test("transaction.broadcast → fails for malformed raw-tx")
    func broadcastRejectsGarbage() async throws {
        await #expect(throws: Swift.Error.self) {
            try await withRunningNode {
                _ = try await fulcrum.submit(
                    method: .blockchain(.transaction(.broadcast(rawTransaction: "DEADBEEF"))),
                    responseType: Response.Result.Blockchain.Transaction.Broadcast.self)
            }
        }
    }
    
    /// Fulcrum Method: Blockchain.Transaction.Get
    @Test("transaction.get → decodes basic fields")
    func getTransaction() async throws {
        let transaction = try await withRunningNode {
            let response = try await fulcrum.submit(method: .blockchain(.transaction(.get(transactionHash: sampleTxID, verbose: true))),
                                                    responseType: Response.Result.Blockchain.Transaction.Get.self)
            guard case .single(let id, let result) = response else { #expect(Bool(false)); throw Fulcrum.Error.coding(.decode(nil)) }
            print("Request ID: \(id.uuidString)")
            
            return result
        }
        
        print("txid: \(transaction.transactionID)  size: \(transaction.size) bytes")
        print("rawHex: \(transaction.hex)")
        #expect(transaction.transactionID == sampleTxID)
        #expect(transaction.size > 0)
        #expect(transaction.inputs.count > 0)
        #expect(transaction.outputs.count > 0)
    }
    
    /// Fulcrum Method: Blockchain.Transaction.GetConfirmedBlockHash
    @Test("transaction.get_confirmed_blockhash → has height + hash")
    func confirmedBlockHash() async throws {
        let infoWithoutHeader = try await withRunningNode {
            let response = try await fulcrum.submit(method: .blockchain(.transaction(.getConfirmedBlockHash(transactionHash: sampleTxID,
                                                                                                            includeHeader: false))),
                                                    responseType: Response.Result.Blockchain.Transaction.GetConfirmedBlockHash.self)
            guard case .single(let id, let result) = response else { #expect(Bool(false)); throw Fulcrum.Error.coding(.decode(nil)) }
            print("Request ID: \(id.uuidString)")
            
            return result
        }
        
        print("block hash: \(infoWithoutHeader.blockHash)  height: \(infoWithoutHeader.blockHeight)")
        #expect(infoWithoutHeader.blockHash.count == 64)
        #expect(infoWithoutHeader.blockHeight > 0)
    }
    
    /// Fulcrum Method: Blockchain.Transaction.GetHeight
    @Test("transaction.get_height → positive height")
    func getHeight() async throws {
        let confirmed = try await withRunningNode {
            let response = try await fulcrum.submit(method:
                    .blockchain(
                        .transaction(
                            .getConfirmedBlockHash(transactionHash: sampleTxID,
                                                   includeHeader: false)
                        )
                    ),
                                                    responseType: Response.Result.Blockchain.Transaction.GetConfirmedBlockHash.self)
            guard case .single(let id, let result) = response else { #expect(Bool(false)); throw Fulcrum.Error.coding(.decode(nil)) }
            print("Request ID: \(id.uuidString)")
            
            return result
        }
        
        print("height: \(confirmed.blockHeight)")
        #expect(confirmed.blockHeight > 0)
    }
    
    /// Fulcrum Method: Blockchain.Transaction.GetMerkle
    @Test("transaction.get_merkle → returns proof branch + position")
    func getMerkle() async throws {
        let merkle = try await withRunningNode {
            let response = try await fulcrum.submit(method:
                    .blockchain(
                        .transaction(
                            .getMerkle(transactionHash: sampleTxID)
                        )
                    ),
                                                    responseType: Response.Result.Blockchain.Transaction.GetMerkle.self)
            guard case .single(let id, let result) = response else { #expect(Bool(false)); throw Fulcrum.Error.coding(.decode(nil)) }
            print("Request ID: \(id.uuidString)")
            
            return result
        }
        
        print("merkle branch length: \(merkle.merkle.count)")
        #expect(merkle.blockHeight > 0)
        #expect(merkle.merkle.count > 0)
    }
    
    /// Fulcrum Method: Blockchain.Transaction.IDFromPos
    @Test("transaction.id_from_pos → round-trip txid")
    func idFromPos() async throws {
        // First, discover (height, pos) from get_merkle so the test is data-driven.
        let merkle = try await withRunningNode {
            let response = try await fulcrum.submit(method:
                    .blockchain(
                        .transaction(
                            .getMerkle(transactionHash: sampleTxID)
                        )
                    ),
                                                    responseType: Response.Result.Blockchain.Transaction.GetMerkle.self)
            guard case .single(let id, let result) = response else { #expect(Bool(false)); throw Fulcrum.Error.coding(.decode(nil)) }
            print("Request ID: \(id.uuidString)")
            
            return result
        }
        
        let roundTrip = try await withRunningNode {
            let response = try await fulcrum.submit(method:
                    .blockchain(
                        .transaction(
                            .idFromPos(blockHeight: merkle.blockHeight, transactionPosition: merkle.position, includeMerkleProof: true)
                        )
                    ),
                                                    responseType: Response.Result.Blockchain.Transaction.IDFromPos.self)
            guard case .single(let id, let result) = response else { #expect(Bool(false)); throw Fulcrum.Error.coding(.decode(nil)) }
            print("Request ID: \(id.uuidString)")
            
            return result
        }
        
        print("round-trip tx_hash: \(roundTrip.transactionHash)")
        #expect(roundTrip.transactionHash == sampleTxID)
    }
}

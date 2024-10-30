import Testing
import Foundation
@testable import SwiftFulcrum

@Suite("Blockchain Transaction Method Tests")
struct BlockchainTransactionMethodTests {
    let fulcrum: Fulcrum
    
    init() async throws {
        self.fulcrum = try .init()
        
        try await self.fulcrum.start()
    }
}

extension BlockchainTransactionMethodTests {
    @Test func testBroadcast() async {
        let rawTransaction = "0200000001dd153fe093c32b47ce68c088664674efbfaee8ee56b2cfc0aa9bbd32ae2b05e9010000006a4730440220701f6fccbd9e6618b4b7a83fc6d60d78b818fa94f6ae55d754cb1be960fb95be022073cfa92e5803ce22a11a833355594ffcbf910bcbb01fdb335c7650765040dc154121021754ab79b784c19a0b4216bde48c80d8beb948a35b0868933d64b4ee8a4c0dfbffffffff0258020000000000001976a914327286de44846065b8812dbef68ec1dab38834f088ac18130000000000001976a914b8759fb3cbe426c6a47365c2cce3a900d18a046888ac00000000"
        
        do {
            let (id, transactionHash) = try await fulcrum.submit(
                method:
                    Method
                    .blockchain(.transaction(.broadcast(rawTransaction: rawTransaction))),
                responseType:
                    Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.Broadcast>.self
            )
            
            try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
            
            #expect(!transactionHash.isEmpty)
            
            print("Raw Tx: \(rawTransaction)")
        } catch Fulcrum.Error.serverError(let code, let message) {
            let inlineMessage = message.replacingOccurrences(of: "\n\n", with: ": ").replacingOccurrences(of: "\n", with: "")
            print("Error code: \(code), message: \(inlineMessage)")
        } catch {
            print(error)
        }
    }
    
    @Test func testGet() async throws {
        let (id, result) = try await fulcrum.submit(
            method:
                Method
                .blockchain(.transaction(.get(transactionHash: "d88c60352520372fac57ee22fe39e2af50e46ac16871edfe727bc49fafdf7201", verbose: true))),
            responseType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.Get>.self
        )
        
        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
        
        try #require(result.hash == "d88c60352520372fac57ee22fe39e2af50e46ac16871edfe727bc49fafdf7201")
        try #require(result.blockhash == "000000000000000000b566ebf051d397992d62a90631b3a4f177d07e891cefc8")
    }
    
    @Test func testGetConfirmedBlockHash() async throws {
        let (id, result) = try await fulcrum.submit(
            method:
                Method
                .blockchain(.transaction(.getConfirmedBlockHash(transactionHash: "d88c60352520372fac57ee22fe39e2af50e46ac16871edfe727bc49fafdf7201", includeHeader: true))),
            responseType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.GetConfirmedBlockHash>.self
        )
        
        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
        try #require(result.block_hash == "000000000000000000b566ebf051d397992d62a90631b3a4f177d07e891cefc8")
        try #require(result.block_height == 869909)
    }
    
    @Test func testGetHeight() async throws {
        let (id, result) = try await fulcrum.submit(
            method:
                Method
                .blockchain(.transaction(.getHeight(transactionHash: "d88c60352520372fac57ee22fe39e2af50e46ac16871edfe727bc49fafdf7201"))),
            responseType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.GetHeight>.self
        )
        
        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
        try #require(result == 869909)
    }
    
    @Test func testGetMerkle() async throws {
        let (id, result) = try await fulcrum.submit(
            method:
                Method
                .blockchain(.transaction(.getMerkle(transactionHash: "d88c60352520372fac57ee22fe39e2af50e46ac16871edfe727bc49fafdf7201"))),
            responseType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.GetMerkle>.self
        )
        
        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
        try #require(result.block_height == 869909)
        
        print("Position: \(result.pos)")
        print("Merkle: \(result.merkle)")
    }
    
    @Test func testIDFromPos() async throws {
        let (id, result) = try await fulcrum.submit(
            method:
                Method
                .blockchain(.transaction(.idFromPos(blockHeight: 869909,
                                                    transactionPosition: 300,
                                                    includeMerkleProof: true))),
            responseType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.IDFromPos>.self
        )
        
        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
        try #require(result.tx_hash == "d88c60352520372fac57ee22fe39e2af50e46ac16871edfe727bc49fafdf7201")
        
        print("Transaction Hash: \(result.tx_hash)")
        print("Merkle: \(result.merkle)")
    }
}

extension BlockchainTransactionMethodTests {
    @Test func testTransactionSubscribeResponse() async throws {
        let (id, result) = try await fulcrum.submit(
            method:
                Method
                .blockchain(.transaction(.subscribe(transactionHash: "d88c60352520372fac57ee22fe39e2af50e46ac16871edfe727bc49fafdf7201"))),
            responseType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.Subscribe>.self
        )
        
        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
        
        switch result {
        case .height(let height):
            print("Height: \(height)")
        case .transactionHashAndHeight(let transactionHashAndHeight):
            print(transactionHashAndHeight)
        }
    }
    
    @Test func testTransactionSubscribeNotification() async throws {
        let (id, initialResponse, notificationStream) = try await fulcrum.submit(
            method:
                Method
                .blockchain(.transaction(.subscribe(transactionHash: "867fcc68574a55bef1ff11d914a3d4c3e14c41d34928fa0e071619c98f07c6a9"))),
            notificationType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.Subscribe>.self
        )
        
        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
        
        switch initialResponse {
        case .height(let height):
            print("Height: \(height)")
            
            if height == 0 {
                for await notification in notificationStream {
                    switch notification {
                    case .height(let height):
                        print("Height: \(height)")
                    case .transactionHashAndHeight(let transactionHashAndHeight):
                        print(transactionHashAndHeight)
                        
                        for item in transactionHashAndHeight {
                            switch item {
                            case .transactionHash(let transactionHash):
                                print("Transaction Hash: \(transactionHash)")
                            case .height(let height):
                                print("Height: \(height)")
                                #expect(height > 0)
                                if height > 0 {
                                    print("Transaction is confirmed with height \(height). Test passed.")
                                    return
                                }
                            }
                        }
                    case .none:
                        print("Nil!")
                    }
                }
            } else {
                print("The transaction is confirmed at \(height).")
            }
        case .transactionHashAndHeight(let transactionHashAndHeight):
            print("\(transactionHashAndHeight), this ain't right.")
        case .none:
            print("Nil!")
        }
    }
    
    @Test func testTransactionUnsubscribe() async throws {
        let (id, initialResponse, notificationStream) = try await fulcrum.submit(
            method:
                Method
                .blockchain(.transaction(.subscribe(transactionHash: "f4f1355f3b43e86bcfd14721f417c813e36bc1f284a7d6c3b8c85d5a85c50881"))),
            notificationType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.Subscribe>.self
        )
        
        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
        
        switch initialResponse {
        case .height(let height):
            print("Height: \(height)")
            if height == 0 {
                for await notification in notificationStream {
                    switch notification {
                    case .height(let height):
                        print("Height: \(height)")
                    case .transactionHashAndHeight(let transactionHashAndHeight):
                        print(transactionHashAndHeight)
                        for item in transactionHashAndHeight {
                            switch item {
                            case .transactionHash(let transactionHash):
                                print("Transaction Hash: \(transactionHash)")
                            case .height(let height):
                                print("Height: \(height)")
                                #expect(height > 0)
                            }
                        }
                        
                        let (id, result) = try await fulcrum.submit(
                            method:
                                Method
                                .blockchain(.transaction(.unsubscribe(transactionHash: "f4f1355f3b43e86bcfd14721f417c813e36bc1f284a7d6c3b8c85d5a85c50881"))),
                            responseType:
                                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.Unsubscribe>.self)
                        
                        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
                        
                        switch result {
                        case true:
                            print("Successfully unsubscribed.")
                            try await Task.sleep(for: .seconds(1))
                            return
                        case false:
                            print("Unsubscription failed.")
                        }
                    case .none:
                        print("Nil!")
                    }
                }
            } else {
                print("The transaction is confirmed at \(height).")
            }
        case .transactionHashAndHeight(let transactionHashAndHeight):
            print("\(transactionHashAndHeight), this ain't right.")
        case .none:
            print("Nil!")
        }
    }
}

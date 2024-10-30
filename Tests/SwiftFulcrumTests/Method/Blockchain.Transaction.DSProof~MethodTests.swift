import Testing
import Foundation
@testable import SwiftFulcrum

@Suite("Blockchain Transaction DSProof Method Tests")
struct BlockchainTransactionDSProofMethodTests {
    let fulcrum: Fulcrum
    
    init() async throws {
        self.fulcrum = try .init()
        
        try await self.fulcrum.start()
    }
}

extension BlockchainTransactionDSProofMethodTests {
    @Test func testDSProofGet() async {
        do {
            let (id, result) = try await fulcrum.submit(
                method:
                    Method
                    .blockchain(.transaction(.dsProof(.get(transactionHash: "867fcc68574a55bef1ff11d914a3d4c3e14c41d34928fa0e071619c98f07c6a9")))),
                responseType:
                    Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Get>.self
            )
            
            try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
            
            print(result)
        } catch Fulcrum.Error.resultNotFound(let description) {
            print("Result not found error: \(description)")
        } catch {
            print(error)
        }
    }
    
    @Test func testDSProofList() async throws {
        let (id, result) = try await fulcrum.submit(
            method:
                Method
                .blockchain(.transaction(.dsProof(.list))),
            responseType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.DSProof.List>.self
        )
        
        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
        
        print(result)
    }
    
    @Test func testDSProofSubscribeResponse() async {
        do {
            let (id, result) = try await fulcrum.submit(
                method:
                    Method
                    .blockchain(.transaction(.dsProof(.subscribe(transactionHash: "0f257b1fa2786950935338d149f48d917e2c4d660d7e1cb7fcceb8629f66e081")))),
                responseType:
                    Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Subscribe>.self
            )
            
            try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
            
            print(result)
        } catch Fulcrum.Error.resultNotFound(let description) {
            print("Result not found error: \(description)")
        } catch {
            print(error)
        }
    }
    
    @Test func testDSProofSubscribeNotification() async throws {
        let (id, initialResponse, notificationStream) = try await fulcrum.submit(
            method:
                Method
                .blockchain(.transaction(.dsProof(.subscribe(transactionHash: "6caa0900477cb17dfbf9d63d034dc6152ebaae97c81bdd1430df43b1f5c445d0")))),
            notificationType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Subscribe>.self
        )
        
        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
        
        switch initialResponse {
        case .dsProof(let dsProof):
            if let dsProof {
                print("DSProof: \(dsProof)")
                
                for await notification in notificationStream {
                    switch notification {
                    case .dsProof(let dsProof):
                        if let dsProof {
                            print("DSProof: \(dsProof)")
                        }
                    case .transactionHashAndDSProof(let transactionHashAndDSProof):
                        print("\(transactionHashAndDSProof)")
                    case .none:
                        print("Nil!")
                    }
                }
            }
        case .transactionHashAndDSProof(let transactionHashAndDSProof):
            print("\(transactionHashAndDSProof), this ain't right.")
        case .none:
            print("Nil!")
        }
    }
    
    @Test func testTransactionUnsubscribe() async throws {
        let (id, initialResponse, notificationStream) = try await fulcrum.submit(
            method:
                Method
                .blockchain(.transaction(.dsProof(.subscribe(transactionHash: "6caa0900477cb17dfbf9d63d034dc6152ebaae97c81bdd1430df43b1f5c445d0")))),
            notificationType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Subscribe>.self
        )
        
        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
        
        switch initialResponse {
        case .dsProof(let dsProof):
            if let dsProof {
                print("DSProof: \(dsProof)")
                
                for await notification in notificationStream {
                    switch notification {
                    case .dsProof(let dsProof):
                        if let dsProof {
                            print("DSProof: \(dsProof)")
                        }
                    case .transactionHashAndDSProof(let transactionHashAndDSProof):
                        print("\(transactionHashAndDSProof)")
                    case .none:
                        print("Nil!")
                        
                        let (id, result) = try await fulcrum.submit(
                            method:
                                Method
                                .blockchain(.transaction(.unsubscribe(transactionHash: "6caa0900477cb17dfbf9d63d034dc6152ebaae97c81bdd1430df43b1f5c445d0"))),
                            responseType:
                                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Unsubscribe>.self)
                        
                        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
                        
                        switch result {
                        case true:
                            print("Successfully unsubscribed.")
                            try await Task.sleep(for: .seconds(1))
                            return
                        case false:
                            print("Unsubscription failed.")
                        }
                    }
                }
            }
        case .transactionHashAndDSProof(let transactionHashAndDSProof):
            print("\(transactionHashAndDSProof), this ain't right.")
        case .none:
            print("Nil!")
        }
    }
}

import Testing
import Foundation
@testable import SwiftFulcrum

@Suite("Blockchain Header Method Tests")
struct BlockchainHeaderMethodTests {
    let fulcrum: Fulcrum
    
    init() async throws {
        self.fulcrum = try .init()
        
        try await self.fulcrum.start()
    }
}

extension BlockchainHeaderMethodTests {
    @Test func testGet() async throws {
        let (id, result) = try await fulcrum.submit(
            method:
                Method
                .blockchain(.header(.get(blockHash: "000000000000000000ddc8f1a4687219e92c1290816683c1ffb4985f96d20e66"))),
            responseType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Header.Get>.self
        )
        
        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
        
        #expect(result.height == 869874)
        
        print("Block Header: \(result)")
    }
}

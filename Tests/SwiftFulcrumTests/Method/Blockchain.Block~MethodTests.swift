import Testing
import Foundation
@testable import SwiftFulcrum

@Suite("Blockchain Block Method Tests")
struct BlockchainBlockMethodTests {
    let fulcrum: Fulcrum
    
    init() async throws {
        self.fulcrum = try .init()
        
        try await self.fulcrum.start()
    }
}

extension BlockchainBlockMethodTests {
    @Test func testHeader() async throws {
        let (id, result) = try await fulcrum.submit(
            method:
                Method
                .blockchain(.block(.header(height: 12345, checkpointHeight: nil))),
            responseType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Block.Header>.self
        )
        
        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
        
        print("Block Header: \(result)")
    }
    
    @Test func testHeaders() async throws {
        let (id, result) = try await fulcrum.submit(
            method:
                Method
                .blockchain(.block(.headers(startHeight: 0, count: 1, checkpointHeight: nil))),
            responseType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Block.Headers>.self
        )
        
        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
        
        print("Block Headers: \(result)")
    }
}

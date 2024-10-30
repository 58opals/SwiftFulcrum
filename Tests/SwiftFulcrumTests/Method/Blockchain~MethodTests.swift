import Testing
import Foundation
@testable import SwiftFulcrum

@Suite("Blockchain Method Tests")
struct BlockchainMethodTests {
    let fulcrum: Fulcrum
    
    init() async throws {
        self.fulcrum = try .init()
        
        try await self.fulcrum.start()
    }
}

extension BlockchainMethodTests {
    @Test func testEstimateFee() async throws {
        let (id, result) = try await fulcrum.submit(
            method:
                Method
                .blockchain(.estimateFee(numberOfBlocks: 6)),
            responseType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.EstimateFee>.self
        )
        
        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
        
        #expect(result > 0, "Estimated fee should be greater than zero.")
        #expect(result < 0.00010000, "Estimated fee should be less than 10,000 satoshis.")
        
        print("Estimated Fee for 6 blocks: \(result)")
    }
    
    @Test func testRelayFee() async throws {
        let (id, result) = try await fulcrum.submit(
            method:
                Method
                .blockchain(.relayFee),
            responseType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.RelayFee>.self
        )
        
        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
        
        #expect(result > 0, "Relay fee should be greater than zero.")
        #expect(result < 0.00010000, "Relay fee should be less than 10,000 satoshis.")
        
        print("Relay Fee: \(result)")
    }
}

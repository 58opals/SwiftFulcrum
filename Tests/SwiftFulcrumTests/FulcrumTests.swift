import Testing
import Foundation
@testable import SwiftFulcrum

@Suite("Fulcrum Tests")
struct FulcrumTests {
    let fulcrum: Fulcrum
    
    init() async throws {
        self.fulcrum = try .init()
        
        try await self.fulcrum.start()
    }
}

extension FulcrumTests {
    @Test func testSubmitRequestSuccess() async throws {
        let (id, result) = try await fulcrum.submit(method:
                .blockchain(.relayFee),
                                 responseType:
                                    Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.RelayFee>.self
        )
        
        print(id.uuidString)
        print(result)
    }
}

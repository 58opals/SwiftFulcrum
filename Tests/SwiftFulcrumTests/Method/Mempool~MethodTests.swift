import Testing
import Foundation
@testable import SwiftFulcrum

@Suite("Mempool Method Tests")
struct MempoolMethodTests {
    let fulcrum: Fulcrum
    
    init() async throws {
        self.fulcrum = try .init()
        
        try await self.fulcrum.start()
    }
}

extension MempoolMethodTests {
    @Test func testGetFeeHistogram() async throws {
        let (id, result) = try await fulcrum.submit(
            method:
                Method
                .mempool(.getFeeHistogram),
            responseType:
                Response.JSONRPC.Generic<Response.JSONRPC.Result.Mempool.GetFeeHistogram>.self
        )
        
        try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
        
        var feeHistogram: [UInt: UInt] = [:]
        for histogram in result {
            try #require(histogram.count == 2)
            let fee = histogram[0]
            let accumulatedBytes = histogram[1]
            feeHistogram[fee] = accumulatedBytes
        }
        
        for (fee, accumulatedBytes) in feeHistogram {
            #expect(fee > 0)
            #expect(accumulatedBytes > 0)
            print("At the fee of \(fee), the accumulated bytes is \(accumulatedBytes).")
        }
    }
}

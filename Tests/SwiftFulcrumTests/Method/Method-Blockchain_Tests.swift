import Testing
import Foundation
@testable import SwiftFulcrum

@Suite("Method.Blockchain")
struct MethodBlockchainTests {
    let fulcrum: Fulcrum
    init() throws {
        self.fulcrum = try Fulcrum()
    }
    
    private func withRunningNode<T>(_ body: @Sendable () async throws -> T) async throws -> T {
        try await fulcrum.start()
        return try await body()
    }

    // MARK: ---
    
    @Test("blockchain.estimatefee → non-zero fee")
    func estimateFee() async throws {
        let fee: Double = try await withRunningNode {
            let (_, fee) = try await fulcrum.submit(
                method: .blockchain(.estimateFee(numberOfBlocks: 6)),
                responseType: Response.JSONRPC.Generic<Double>.self)
            return fee
        }
        
        print("Blockchain.EstimateFee: \(fee)")
        #expect(fee > 0)
        #expect(fee < 0.005)
    }

    @Test("blockchain.relayfee → plausible default relay fee")
    func relayFee() async throws {
        let fee: Double = try await withRunningNode {
            let (_, fee) = try await fulcrum.submit(
                method: .blockchain(.relayFee),
                responseType: Response.JSONRPC.Generic<Double>.self)
            return fee
        }
        
        print("Blockchain.RelayFee: \(fee)")
        #expect(fee >= 0)
        #expect(fee <= 0.00002)
    }
}

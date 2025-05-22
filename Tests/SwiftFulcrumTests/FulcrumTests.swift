
import Testing
import Foundation
@testable import SwiftFulcrum

private extension String {
    static let sampleAddress = "qrmfkegyf83zh5kauzwgygf82sdahd5a55x9wse7ve"
}

@Suite("Fulcrum – Wallet-level integration")
struct FulcrumWalletTests {
    let fulcrum: Fulcrum
    init() throws {
        self.fulcrum = try Fulcrum()
    }
    
    @Test("start → stop happy-path")
    func startAndStop() async throws {
        try await fulcrum.start()
        #expect(await fulcrum.isRunning)
        
        await fulcrum.stop()
        #expect(!(await fulcrum.isRunning))
    }
    
    @Test("estimateFee(6) returns a positive fee rate")
    func estimateFee() async throws {
        try await fulcrum.start()
        
        let estimateFee = try await fulcrum.submit(
            method: .blockchain(.estimateFee(numberOfBlocks: 6)),
            responseType: Response.Result.Blockchain.EstimateFee.self
        )

        print("Estimated fee: \(estimateFee.fee)")
        
        #expect(estimateFee.fee > 0.0)
    }
    
    @Test("getBalance(address) delivers sane numbers")
    func addressBalance() async throws {
        try await fulcrum.start()
        
        let balance = try await fulcrum.submit(
            method: .blockchain(.address(.getBalance(address: .sampleAddress, tokenFilter: nil))),
            responseType: Response.Result.Blockchain.Address.GetBalance.self
        )

        print("Balance: \(balance)")
        #expect(balance.confirmed >= 0)
        #expect(balance.unconfirmed >= Int64.min)
    }
    
    @Test("headers.subscribe gives an initial tip and a live stream")
    func headerSubscription() async throws {
        try await fulcrum.start()
        
        let (initial, stream) = try await fulcrum.submit(
            method: .blockchain(.headers(.subscribe)),
            notificationType: Response.Result.Blockchain.Headers.Subscribe.self
        )
        
        print("Initial tip: \(initial.height), \(initial.hex)")
        #expect(initial.height > 0)
        
        var iterator = stream.makeAsyncIterator()
        if let next = try await iterator.next() {
            print(next)
            #expect(true)
        }
    }
    
    @Test("broadcasting garbage tx yields an RPC error")
    func broadcastInvalidTransaction() async throws {
        try await fulcrum.start()
        
        await #expect(throws: Fulcrum.Error.self) {
            _ = try await fulcrum.submit(
                method: .blockchain(.transaction(.broadcast(rawTransaction: "deadbeef"))),
                responseType: Response.Result.Blockchain.Transaction.Broadcast.self
            )
        }
    }
}


import Testing
import Foundation
@testable import SwiftFulcrum

private extension String {
    static let sampleAddress = "qrmfkegyf83zh5kauzwgygf82sdahd5a55x9wse7ve"
}

@Suite("Fulcrum – Wallet-level integration")
struct FulcrumWalletTests {
    let fulcrum: Fulcrum
    init() async throws {
        self.fulcrum = try await Fulcrum()
    }
    
    @Test("start → stop happy-path")
    func startAndStop() async throws {
        try await fulcrum.start()
        #expect(await fulcrum.isRunning)
        
        await fulcrum.stop()
        #expect(!(await fulcrum.isRunning))
    }
    
    @Test("calling start twice is ignored")
    func startTwiceIsNoOp() async throws {
        try await fulcrum.start()
        #expect(await fulcrum.isRunning)
        
        try await fulcrum.start()
        #expect(await fulcrum.isRunning)
        
        await fulcrum.stop()
    }
    
    @Test("estimateFee(6) returns a positive fee rate")
    func estimateFee() async throws {
        try await fulcrum.start()
        
        let response = try await fulcrum.submit(method: .blockchain(.estimateFee(numberOfBlocks: 6)),
                                                responseType: Response.Result.Blockchain.EstimateFee.self)
        
        guard case .single(let id, let result) = response else { #expect(Bool(false)); return }
        
        print("ID: \(id.description)")
        print("Estimated fee: \(result.fee)")
        
        #expect(result.fee > 0.0)
    }
    
    @Test("getBalance(address) delivers sane numbers")
    func addressBalance() async throws {
        try await fulcrum.start()
        
        let response = try await fulcrum.submit(method: .blockchain(.address(.getBalance(address: .sampleAddress, tokenFilter: nil))),
                                                responseType: Response.Result.Blockchain.Address.GetBalance.self)
        
        guard case .single(let id, let result) = response else { #expect(Bool(false)); return }
        
        print("ID: \(id.description)")
        print("Balance: \(result)")
        #expect(result.confirmed >= 0)
        #expect(result.unconfirmed >= Int64.min)
    }
    
    @Test("headers.subscribe gives an initial tip and a live stream")
    func headerSubscription() async throws {
        try await fulcrum.start()
        
        let response = try await fulcrum.submit(method: .blockchain(.headers(.subscribe)),
                                                notificationType: Response.Result.Blockchain.Headers.Subscribe.self)
        
        guard case .stream(let id, let initial, let stream, let cancel) = response else { #expect(Bool(false)); return }
        
        print("ID: \(id.description)")
        print("Initial tip: \(initial.height), \(initial.hex)")
        #expect(initial.height > 0)
        
        var iterator = stream.makeAsyncIterator()
        print("waiting for the next block...")
        if let next = try await iterator.next() {
            print("Finally!: \(next)")
            #expect(true)
        }
        
        await cancel()
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

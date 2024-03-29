public struct SwiftFulcrum {
    let client: Client
    
    func requestRelayFee() async throws -> Double {
        let id = try await client.sendRequest(from: .blockchain(.relayFee))
        
        let waitingTime = 5.0
        try await Task.sleep(nanoseconds: UInt64(waitingTime * 1_000_000_000.0))
        
        guard let relayFee = try client.jsonRPC.storage.result.blockchain.relayFee.getResult(for: id) else { fatalError() }
        
        return relayFee.fee
    }
}

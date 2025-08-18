import Testing
import Foundation
@testable import SwiftFulcrum

@Suite("Method.Blockchain / UTXO / Mempool – Regular RPCs")
struct MethodBlockchainTests {
    let fulcrum: Fulcrum
    init() async throws { self.fulcrum = try await Fulcrum() }
    
    private func withRunningNode<T>(_ body: @Sendable () async throws -> T) async throws -> T {
        try await fulcrum.start()
        return try await body()
    }
}

extension MethodBlockchainTests {
    /// Fulcrum Method: Blockchain.EstimateFee
    @Test("blockchain.estimatefee → non-zero fee")
    func estimateFee() async throws {
        let fee = try await withRunningNode {
            let response = try await fulcrum.submit(method: .blockchain(.estimateFee(numberOfBlocks: 6)),
                                                    responseType: Response.Result.Blockchain.EstimateFee.self)
            guard case .single(let id, let result) = response else { #expect(Bool(false)); throw Fulcrum.Error.coding(.decode(nil)) }
            print("Request ID: \(id.uuidString)")
            
            return result.fee
        }
        
        print("Blockchain.EstimateFee: \(fee)")
        #expect(fee > 0)
        #expect(fee < 0.005)
    }
    
    /// Fulcrum Method: Blockchain.RelayFee
    @Test("blockchain.relayfee → plausible default relay fee")
    func relayFee() async throws {
        let fee = try await withRunningNode {
            let response = try await fulcrum.submit(method: .blockchain(.relayFee),
                                                    responseType: Response.Result.Blockchain.RelayFee.self)
            guard case .single(let id, let result) = response else { #expect(Bool(false)); throw Fulcrum.Error.coding(.decode(nil)) }
            print("Request ID: \(id.uuidString)")
            
            return result.fee
        }
        
        print("Blockchain.RelayFee: \(fee)")
        #expect(fee >= 0)
        #expect(fee <= 0.00002)
    }
    
    /// Fulcrum Method: Blockchain.UTXO.GetInfo
    @Test("utxo.get_info → decodes when a spendable outpoint exists")
    func utxoGetInfo() async throws {
        let address = "qrmfkegyf83zh5kauzwgygf82sdahd5a55x9wse7ve"
        
        let utxos = try await withRunningNode {
            let response = try await fulcrum.submit(method: .blockchain(.address(.listUnspent(address: address,
                                                                                              tokenFilter: .include))),
                                                    responseType: Response.Result.Blockchain.Address.ListUnspent.self)
            guard case .single(let id, let result) = response else { #expect(Bool(false)); throw Fulcrum.Error.coding(.decode(nil)) }
            print("Request ID: \(id.uuidString)")
            
            return result.items
        }
        
        for utxo in utxos {
            print("utxo: \(utxo)")
            
            let response = try await fulcrum.submit(method: .blockchain(.utxo(.getInfo(transactionHash: utxo.transactionHash,
                                                                                       outputIndex: UInt16(utxo.transactionPosition)))),
                                                    responseType: Response.Result.Blockchain.UTXO.GetInfo.self)
            guard case .single(let id, let information) = response else { #expect(Bool(false)); throw Fulcrum.Error.coding(.decode(nil)) }
            print("Request ID: \(id.uuidString)")
            
            print("information: \(information)")
            if let height = information.confirmedHeight { #expect(height >= 0) }
            #expect(information.value == utxo.value)
        }
    }
    
    /// Fulcrum Method: Mempool.GetFeeHistogram
    @Test("mempool.get_fee_histogram → returns ≥ 1 bucket")
    func feeHistogram() async throws {
        let histogram = try await withRunningNode {
            let response = try await fulcrum.submit(method: .mempool(.getFeeHistogram),
                                                    responseType: Response.Result.Mempool.GetFeeHistogram.self)
            guard case .single(let id, let result) = response else { #expect(Bool(false)); throw Fulcrum.Error.coding(.decode(nil)) }
            print("Request ID: \(id.uuidString)")
            
            return result.histogram
        }
        
        print("fee histogram rows \(histogram.count)")
        print("fee histogram: \(histogram)")
        #expect(histogram.count > 0)
        for row in histogram { print(row) }
    }
}

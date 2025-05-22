import Testing
import Foundation
@testable import SwiftFulcrum

@Suite("Method.Blockchain / UTXO / Mempool – Regular RPCs")
struct MethodBlockchainTests {
    let fulcrum: Fulcrum
    init() throws { self.fulcrum = try Fulcrum() }
    
    private func withRunningNode<T>(_ body: @Sendable () async throws -> T) async throws -> T {
        try await fulcrum.start()
        return try await body()
    }
}

extension MethodBlockchainTests {
    /// Fulcrum Method: Blockchain.EstimateFee
    @Test("blockchain.estimatefee → non-zero fee")
    func estimateFee() async throws {
        let fee: Double = try await withRunningNode {
            let fee = try await fulcrum.submit(
                method: .blockchain(.estimateFee(numberOfBlocks: 6)),
                responseType: Response.Result.Blockchain.EstimateFee.self)
            return fee.fee
        }
        
        print("Blockchain.EstimateFee: \(fee)")
        #expect(fee > 0)
        #expect(fee < 0.005)
    }
    
    /// Fulcrum Method: Blockchain.RelayFee
    @Test("blockchain.relayfee → plausible default relay fee")
    func relayFee() async throws {
        let fee: Double = try await withRunningNode {
            let fee = try await fulcrum.submit(
                method: .blockchain(.relayFee),
                responseType: Response.Result.Blockchain.RelayFee.self)
            return fee.fee
        }
        
        print("Blockchain.RelayFee: \(fee)")
        #expect(fee >= 0)
        #expect(fee <= 0.00002)
    }
    
    /// Fulcrum Method: Blockchain.UTXO.GetInfo
    @Test("utxo.get_info → decodes when a spendable outpoint exists")
    func utxoGetInfo() async throws {
        let address = "qrmfkegyf83zh5kauzwgygf82sdahd5a55x9wse7ve"
        try await withRunningNode {
            let utxos = try await fulcrum.submit(
                method: .blockchain(.address(.listUnspent(address: address,
                                                          tokenFilter: .include))),
                responseType: Response.Result.Blockchain.Address.ListUnspent.self)
            
            guard let first = utxos.items.first else {
                print("No UTXOs on the sample addr → nothing to test")
                return
            }
            
            let info = try await fulcrum.submit(
                method: .blockchain(.utxo(.getInfo(transactionHash: first.transactionHash,
                                                   outputIndex: UInt16(first.transactionPosition)))),
                responseType: Response.Result.Blockchain.UTXO.GetInfo.self)
            
            print("utxo info: \(info)")
            if let height = info.confirmedHeight {
                #expect(height >= 0)
            }
            #expect(info.value == first.value)
        }
    }
    
    /// Fulcrum Method: Mempool.GetFeeHistogram
    @Test("mempool.get_fee_histogram → returns ≥ 1 bucket")
    func feeHistogram() async throws {
        let histogram = try await withRunningNode {
            let rows = try await fulcrum.submit(
                method: .mempool(.getFeeHistogram),
                responseType: Response.Result.Mempool.GetFeeHistogram.self)
            return rows
        }
        
        print("fee histogram rows \(histogram.histogram.count)")
        print("fee histogram: \(histogram.histogram)")
        #expect(histogram.histogram.count > 0)
        for row in histogram.histogram { print(row) }
    }
}

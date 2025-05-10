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
            let (_, fee) = try await fulcrum.submit(
                method: .blockchain(.estimateFee(numberOfBlocks: 6)),
                responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.EstimateFee>.self)
            return fee
        }
        
        print("Blockchain.EstimateFee: \(fee)")
        #expect(fee > 0)
        #expect(fee < 0.005)
    }
    
    /// Fulcrum Method: Blockchain.RelayFee
    @Test("blockchain.relayfee → plausible default relay fee")
    func relayFee() async throws {
        let fee: Double = try await withRunningNode {
            let (_, fee) = try await fulcrum.submit(
                method: .blockchain(.relayFee),
                responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.RelayFee>.self)
            return fee
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
            let (_, utxos) = try await fulcrum.submit(
                method: .blockchain(.address(.listUnspent(address: address,
                                                          tokenFilter: .include))),
                responseType: Response.JSONRPC.Generic<
                Response.JSONRPC.Result.Blockchain.Address.ListUnspent>.self)
            
            guard let first = utxos.first else {
                print("No UTXOs on the sample addr → nothing to test")
                return
            }
            
            let (_, info) = try await fulcrum.submit(
                method: .blockchain(.utxo(.getInfo(transactionHash: first.tx_hash,
                                                   outputIndex: UInt16(first.tx_pos)))),
                responseType: Response.JSONRPC.Generic<
                Response.JSONRPC.Result.Blockchain.UTXO.GetInfo>.self)
            
            print("utxo info: \(info)")
            if let height = info.confirmed_height {
                #expect(height >= 0)
            }
            #expect(info.value == first.value)
        }
    }
    
    /// Fulcrum Method: Mempool.GetFeeHistogram
    @Test("mempool.get_fee_histogram → returns ≥ 1 bucket")
    func feeHistogram() async throws {
        let histogram = try await withRunningNode {
            let (_, rows) = try await fulcrum.submit(
                method: .mempool(.getFeeHistogram),
                responseType: Response.JSONRPC.Generic<[[Double]]>.self)
            return rows
        }
        
        print("fee histogram rows \(histogram.count)")
        print("fee histogram: \(histogram)")
        #expect(histogram.count > 0)
        for row in histogram { #expect(row.count == 2) }
    }
}

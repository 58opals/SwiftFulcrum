import Foundation
import Testing
@testable import SwiftFulcrum

@Suite("Mempool fee histogram decoding")
struct MempoolFeeHistogramTests {
    
    // Helper to build a JSON-RPC "regular" response payload
    private func rpc(_ pairs: [[UInt]], id: UUID = UUID()) throws -> Data {
        struct RPCResp<T: Encodable>: Encodable {
            let jsonrpc = "2.0"
            let id: UUID
            let result: T
        }
        return try JSONEncoder().encode(RPCResp(id: id, result: pairs))
    }
    
    @Test
    func decodes_and_sorts_ascending_by_fee() throws {
        // Unsorted input: fee→vsize = [100→10], [5→1000], [50→500]
        let data = try rpc([[100, 10], [5, 1000], [50, 500]])
        let ctx = JSONRPC.DecodeContext(methodPath: Method.mempool(.getFeeHistogram).path)
        
        let decoded = try data.decode(Response.Result.Mempool.GetFeeHistogram.self, context: ctx)
        #expect(decoded.histogram.map(\.fee) == [5, 50, 100])
        #expect(decoded.histogram.map(\.virtualSize) == [1000, 500, 10])
    }
    
    @Test
    func rejects_malformed_pairs() throws {
        // Case 1: entry with 1 element
        do {
            let data = try rpc([[1, 2], [7]])
            let ctx = JSONRPC.DecodeContext(methodPath: Method.mempool(.getFeeHistogram).path)
            _ = try data.decode(Response.Result.Mempool.GetFeeHistogram.self, context: ctx)
            Issue.record("expected failure for 1-element pair")
        } catch let e as Response.Result.Error {
            switch e {
            case .unexpectedFormat(let msg):
                #expect(msg.contains("Malformed entry at index 1"))
                #expect(msg.contains("Histogram entry must be [fee, vsize]"))
                #expect(msg.contains("mempool.get_fee_histogram"))
            default:
                Issue.record("unexpected error type: \(e)")
            }
        }
        
        // Case 2: entry with 3 elements
        do {
            let data = try rpc([[10, 20], [1, 2, 3]])
            let ctx = JSONRPC.DecodeContext(methodPath: Method.mempool(.getFeeHistogram).path)
            _ = try data.decode(Response.Result.Mempool.GetFeeHistogram.self, context: ctx)
            Issue.record("expected failure for 3-element pair")
        } catch let e as Response.Result.Error {
            switch e {
            case .unexpectedFormat(let msg):
                #expect(msg.contains("Malformed entry at index 1"))
                #expect(msg.contains("Histogram entry must be [fee, vsize]"))
            default:
                Issue.record("unexpected error type: \(e)")
            }
        }
    }
}

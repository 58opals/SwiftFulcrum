import Foundation
import Testing
@testable import SwiftFulcrum

@Suite("Mempool fee histogram decoding")
struct MempoolFeeHistogramTests {
    
    private func rpc(_ pairs: [[UInt]], id: UUID = UUID()) throws -> Data {
        struct RPCResponse<T: Encodable>: Encodable {
            let jsonrpc = "2.0"
            let id: UUID
            let result: T
        }
        return try JSONEncoder().encode(RPCResponse(id: id, result: pairs))
    }
    
    @Test
    func decodes_and_sorts_ascending_by_fee() throws {
        let data = try rpc([[100, 10], [5, 1000], [50, 500]])
        let context = JSONRPC.DecodeContext(methodPath: Method.mempool(.getFeeHistogram).path)
        
        let decoded = try data.decode(Response.Result.Mempool.GetFeeHistogram.self, context: context)
        #expect(decoded.histogram.map(\.fee) == [5, 50, 100])
        #expect(decoded.histogram.map(\.virtualSize) == [1000, 500, 10])
    }
    
    @Test
    func rejects_malformed_pairs() throws {
        do {
            let data = try rpc([[1, 2], [7]])
            let context = JSONRPC.DecodeContext(methodPath: Method.mempool(.getFeeHistogram).path)
            _ = try data.decode(Response.Result.Mempool.GetFeeHistogram.self, context: context)
            Issue.record("expected failure for 1-element pair")
        } catch let error as Response.Result.Error {
            switch error {
            case .unexpectedFormat(let message):
                #expect(message.contains("Malformed entry at index 1"))
                #expect(message.contains("Histogram entry must be [fee, vsize]"))
                #expect(message.contains("mempool.get_fee_histogram"))
            default:
                Issue.record("unexpected error type: \(error)")
            }
        }
        
        do {
            let data = try rpc([[10, 20], [1, 2, 3]])
            let context = JSONRPC.DecodeContext(methodPath: Method.mempool(.getFeeHistogram).path)
            _ = try data.decode(Response.Result.Mempool.GetFeeHistogram.self, context: context)
            Issue.record("expected failure for 3-element pair")
        } catch let error as Response.Result.Error {
            switch error {
            case .unexpectedFormat(let message):
                #expect(message.contains("Malformed entry at index 1"))
                #expect(message.contains("Histogram entry must be [fee, vsize]"))
            default:
                Issue.record("unexpected error type: \(error)")
            }
        }
    }
}

// ResponseDecodingValidator~Mempool.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ResponseDecodingValidator {
    @Test("Decodes mempool fee histogram flexible number pairs")
    func decodeMempoolFeeHistogram() throws {
        let payload = try makeJSONData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": [[2.5, 2000], [1, 1000]]]
        )
        let histogram = try payload.decode(
            SwiftFulcrum.Response.Mempool.FeeHistogram.self,
            context: .init(methodPath: "mempool.get_fee_histogram")
        )
        #expect(histogram.histogram.count == 2)
        #expect(histogram.histogram[0].fee == 2.5)
        #expect(histogram.histogram[0].virtualSize == 2000)
        #expect(histogram.histogram[1].fee == 1.0)
        #expect(histogram.histogram[1].virtualSize == 1000)
    }

    @Test("Rejects invalid mempool info fee values")
    func rejectInvalidMempoolInfoFeeValues() throws {
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "mempoolminfee": "nan",
                    "minrelaytxfee": -1,
                    "incrementalrelayfee": "inf"
                ]
            ]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Mempool.Info.self,
                context: .init(methodPath: "mempool.get_info")
            )
        }
    }

    @Test("Rejects negative mempool info unbroadcast count")
    func rejectNegativeMempoolInfoUnbroadcastCount() throws {
        let payload = try makeJSONData(
            [
                "jsonrpc": "2.0",
                "id": UUID().uuidString,
                "result": [
                    "unbroadcastcount": -1
                ]
            ]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Mempool.Info.self,
                context: .init(methodPath: "mempool.get_info")
            )
        }
    }

    @Test("Rejects oversized mempool fee histogram virtual sizes")
    func rejectOversizedMempoolFeeHistogramVirtualSize() throws {
        let payload = try makeJSONData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": [[1, "18446744073709551616"]]]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Mempool.FeeHistogram.self,
                context: .init(methodPath: "mempool.get_fee_histogram")
            )
        }
    }

    @Test("Rejects fractional mempool fee histogram virtual sizes")
    func rejectFractionalMempoolFeeHistogramVirtualSize() throws {
        let payload = try makeJSONData(
            ["jsonrpc": "2.0", "id": UUID().uuidString, "result": [[1, 2000.75]]]
        )

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try payload.decode(
                SwiftFulcrum.Response.Mempool.FeeHistogram.self,
                context: .init(methodPath: "mempool.get_fee_histogram")
            )
        }
    }
}

// FulcrumMethodRequestEncodingValidator~RPA.swift

import Testing
@testable import SwiftFulcrum

extension FulcrumMethodRequestEncodingValidator {
    @Test("Typed RPA endpoints encode exact current protocol parameters")
    func encodeTypedRPAEndpoints() throws {
        let prefix = "aBc"

        try assertEndpoint(
            SwiftFulcrum.API.blockchain.rpa.history(
                prefix: prefix,
                fromHeight: 825_000
            ),
            expectedPath: "blockchain.rpa.get_history",
            expectedParameters: [prefix, 825_000, -1]
        )
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.rpa.history(
                prefix: prefix,
                fromHeight: 825_000,
                toHeight: 825_060
            ),
            expectedPath: "blockchain.rpa.get_history",
            expectedParameters: [prefix, 825_000, 825_060]
        )
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.rpa.mempool(prefix: prefix),
            expectedPath: "blockchain.rpa.get_mempool",
            expectedParameters: [prefix]
        )
    }

    @Test("RPA history preserves an empty inclusive-exclusive interval")
    func encodeEmptyRPAHistoryInterval() throws {
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.rpa.history(
                prefix: "ab",
                fromHeight: 825_000,
                toHeight: 825_000
            ),
            expectedPath: "blockchain.rpa.get_history",
            expectedParameters: ["ab", 825_000, 825_000]
        )
    }
}

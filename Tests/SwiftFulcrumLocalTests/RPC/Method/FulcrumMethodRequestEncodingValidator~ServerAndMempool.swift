// FulcrumMethodRequestEncodingValidator~ServerAndMempool.swift

import Testing
@testable import SwiftFulcrum

extension FulcrumMethodRequestEncodingValidator {
    @Test("Encodes server and mempool request variants")
    func encodeServerAndMempoolRequests() throws {
        try assertRequest(
            .server(.ping),
            expectedPath: SwiftFulcrum.RPC.Method.server(.ping).path,
            expectedParameters: []
        )

        let minimum = try #require(SwiftFulcrum.ProtocolVersion(string: "1.4"))
        let maximum = try #require(SwiftFulcrum.ProtocolVersion(string: "1.6.0"))
        let negotiationRange = try #require(SwiftFulcrum.ProtocolVersion.Range(min: minimum, max: maximum))
        try assertRequest(
            .server(.version(clientName: "SwiftFulcrum/Test", protocolNegotiation: .init(range: negotiationRange))),
            expectedPath: SwiftFulcrum.RPC.Method.server(.version(clientName: "", protocolNegotiation: .init(range: negotiationRange))).path,
            expectedParameters: ["SwiftFulcrum/Test", ["1.4", "1.6.0"]]
        )

        let singleVersion = try #require(SwiftFulcrum.ProtocolVersion(string: "1.5"))
        try assertRequest(
            .server(
                .version(
                    clientName: "SwiftFulcrum/Test",
                    protocolNegotiation: .init(minimumVersion: singleVersion, maximumVersion: singleVersion)
                )
            ),
            expectedPath: SwiftFulcrum.RPC.Method.server(.version(clientName: "", protocolNegotiation: .init(minimumVersion: singleVersion, maximumVersion: singleVersion))).path,
            expectedParameters: ["SwiftFulcrum/Test", "1.5"]
        )

        try assertRequest(
            .server(.features),
            expectedPath: SwiftFulcrum.RPC.Method.server(.features).path,
            expectedParameters: []
        )

        try assertRequest(
            .mempool(.getInfo),
            expectedPath: SwiftFulcrum.RPC.Method.mempool(.getInfo).path,
            expectedParameters: []
        )

        try assertRequest(
            .mempool(.getFeeHistogram),
            expectedPath: SwiftFulcrum.RPC.Method.mempool(.getFeeHistogram).path,
            expectedParameters: []
        )
    }
}

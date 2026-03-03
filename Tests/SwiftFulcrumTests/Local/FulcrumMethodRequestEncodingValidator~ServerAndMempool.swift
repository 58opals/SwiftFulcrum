import Testing
@testable import SwiftFulcrum

extension FulcrumMethodRequestEncodingValidator {
    @Test("Encodes server and mempool request variants")
    func encodeServerAndMempoolRequests() throws {
        try assertRequest(
            .server(.ping),
            expectedPath: FulcrumMethodRequest.server(.ping).path,
            expectedParameters: []
        )

        let minimum = try #require(ProtocolVersionModel(string: "1.4"))
        let maximum = try #require(ProtocolVersionModel(string: "1.6.0"))
        let negotiationRange = try #require(ProtocolVersionModel.Range(min: minimum, max: maximum))
        try assertRequest(
            .server(.version(clientName: "SwiftFulcrum/Test", protocolNegotiation: .init(range: negotiationRange))),
            expectedPath: FulcrumMethodRequest.server(.version(clientName: "", protocolNegotiation: .init(range: negotiationRange))).path,
            expectedParameters: ["SwiftFulcrum/Test", ["1.4", "1.6.0"]]
        )

        let singleVersion = try #require(ProtocolVersionModel(string: "1.5"))
        try assertRequest(
            .server(
                .version(
                    clientName: "SwiftFulcrum/Test",
                    protocolNegotiation: .init(minimumVersion: singleVersion, maximumVersion: singleVersion)
                )
            ),
            expectedPath: FulcrumMethodRequest.server(.version(clientName: "", protocolNegotiation: .init(minimumVersion: singleVersion, maximumVersion: singleVersion))).path,
            expectedParameters: ["SwiftFulcrum/Test", "1.5"]
        )

        try assertRequest(
            .server(.features),
            expectedPath: FulcrumMethodRequest.server(.features).path,
            expectedParameters: []
        )

        try assertRequest(
            .mempool(.getInfo),
            expectedPath: FulcrumMethodRequest.mempool(.getInfo).path,
            expectedParameters: []
        )

        try assertRequest(
            .mempool(.getFeeHistogram),
            expectedPath: FulcrumMethodRequest.mempool(.getFeeHistogram).path,
            expectedParameters: []
        )
    }
}

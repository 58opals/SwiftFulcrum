// FulcrumMethodRequestEncodingValidator~APIEndpoints.swift

import Testing
@testable import SwiftFulcrum

extension FulcrumMethodRequestEncodingValidator {
    @Test("Typed API endpoints encode server and mempool requests")
    func encodeTypedServerAndMempoolEndpoints() throws {
        let minimum = try #require(SwiftFulcrum.ProtocolVersion(string: "1.4"))
        let maximum = try #require(SwiftFulcrum.ProtocolVersion(string: "1.6.0"))
        let negotiationRange = try #require(SwiftFulcrum.ProtocolVersion.Range(min: minimum, max: maximum))

        try assertEndpoint(SwiftFulcrum.API.server.ping, expectedPath: "server.ping", expectedParameters: [])
        try assertEndpoint(
            SwiftFulcrum.API.server.version(
                clientName: "SwiftFulcrum/Test",
                protocolNegotiation: .init(range: negotiationRange)
            ),
            expectedPath: "server.version",
            expectedParameters: ["SwiftFulcrum/Test", ["1.4", "1.6.0"]]
        )
        try assertEndpoint(SwiftFulcrum.API.server.features, expectedPath: "server.features", expectedParameters: [])
        try assertEndpoint(SwiftFulcrum.API.mempool.info, expectedPath: "mempool.get_info", expectedParameters: [])
        try assertEndpoint(SwiftFulcrum.API.mempool.feeHistogram, expectedPath: "mempool.get_fee_histogram", expectedParameters: [])
    }

    @Test("Typed API endpoints preserve scripthash and address wire paths")
    func encodeTypedScriptHashAndAddressEndpoints() throws {
        let scriptHash = String(repeating: "a", count: 64)
        let address = "bitcoincash:qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx6a"

        try assertEndpoint(
            SwiftFulcrum.API.blockchain.scriptHash.balance(scriptHash: scriptHash, tokenFilter: .include),
            expectedPath: "blockchain.scripthash.get_balance",
            expectedParameters: [scriptHash, "include_tokens"]
        )
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.scriptHash.firstUse(scriptHash: scriptHash),
            expectedPath: "blockchain.scripthash.get_first_use",
            expectedParameters: [scriptHash]
        )
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.scriptHash.history(
                scriptHash: scriptHash,
                fromHeight: 5,
                toHeight: 10,
                shouldIncludeUnconfirmed: true
            ),
            expectedPath: "blockchain.scripthash.get_history",
            expectedParameters: [scriptHash, 5, 10]
        )
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.scriptHash.mempool(scriptHash: scriptHash),
            expectedPath: "blockchain.scripthash.get_mempool",
            expectedParameters: [scriptHash]
        )
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.scriptHash.listUnspent(scriptHash: scriptHash, tokenFilter: .only),
            expectedPath: "blockchain.scripthash.listunspent",
            expectedParameters: [scriptHash, "tokens_only"]
        )
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.scriptHash.subscribe(scriptHash: scriptHash),
            expectedPath: "blockchain.scripthash.subscribe",
            expectedParameters: [scriptHash]
        )
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.scriptHash.unsubscribe(scriptHash: scriptHash),
            expectedPath: "blockchain.scripthash.unsubscribe",
            expectedParameters: [scriptHash]
        )

        try assertEndpoint(
            SwiftFulcrum.API.blockchain.address.balance(address: address, tokenFilter: .exclude),
            expectedPath: "blockchain.address.get_balance",
            expectedParameters: [address, "exclude_tokens"]
        )
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.address.firstUse(address: address),
            expectedPath: "blockchain.address.get_first_use",
            expectedParameters: [address]
        )
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.address.history(
                address: address,
                fromHeight: 7,
                toHeight: 9,
                shouldIncludeUnconfirmed: true
            ),
            expectedPath: "blockchain.address.get_history",
            expectedParameters: [address, 7, 9]
        )
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.address.mempool(address: address),
            expectedPath: "blockchain.address.get_mempool",
            expectedParameters: [address]
        )
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.address.scriptHash(address: address),
            expectedPath: "blockchain.address.get_scripthash",
            expectedParameters: [address]
        )
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.address.listUnspent(address: address, tokenFilter: .include),
            expectedPath: "blockchain.address.listunspent",
            expectedParameters: [address, "include_tokens"]
        )
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.address.subscribe(address: address),
            expectedPath: "blockchain.address.subscribe",
            expectedParameters: [address]
        )
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.address.unsubscribe(address: address),
            expectedPath: "blockchain.address.unsubscribe",
            expectedParameters: [address]
        )
    }
}

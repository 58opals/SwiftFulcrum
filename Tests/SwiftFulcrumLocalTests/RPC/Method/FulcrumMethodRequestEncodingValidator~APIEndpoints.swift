// FulcrumMethodRequestEncodingValidator~APIEndpoints.swift

import Testing
@testable import SwiftFulcrum

extension FulcrumMethodRequestEncodingValidator {
    @Test("Typed API endpoints encode server and mempool requests")
    func encodeTypedServerAndMempoolEndpoints() throws {
        let minimum = try #require(SwiftFulcrum.ProtocolVersion(string: "1.4"))
        let maximum = try #require(SwiftFulcrum.ProtocolVersion(string: "1.6.0"))
        let negotiationRange = try #require(SwiftFulcrum.ProtocolVersion.Range(min: minimum, max: maximum))

        try assertEndpoint(.server.ping, expectedPath: "server.ping", expectedParameters: [])
        try assertEndpoint(
            .server.version(
                clientName: "SwiftFulcrum/Test",
                protocolNegotiation: .init(range: negotiationRange)
            ),
            expectedPath: "server.version",
            expectedParameters: ["SwiftFulcrum/Test", ["1.4", "1.6.0"]]
        )
        try assertEndpoint(.server.features, expectedPath: "server.features", expectedParameters: [])
        try assertEndpoint(.mempool.getInfo, expectedPath: "mempool.get_info", expectedParameters: [])
        try assertEndpoint(.mempool.getFeeHistogram, expectedPath: "mempool.get_fee_histogram", expectedParameters: [])
    }

    @Test("Typed API endpoints preserve scripthash and address wire paths")
    func encodeTypedScriptHashAndAddressEndpoints() throws {
        let scriptHash = String(repeating: "a", count: 64)
        let address = "bitcoincash:qpm2qsznhks23z7629mms6s4cwef74vcwvy22gdx6a"

        try assertEndpoint(
            .blockchain.scriptHash.getBalance(scriptHash: scriptHash, tokenFilter: .include),
            expectedPath: "blockchain.scripthash.get_balance",
            expectedParameters: [scriptHash, "include_tokens"]
        )
        try assertEndpoint(
            .blockchain.scriptHash.getFirstUse(scriptHash: scriptHash),
            expectedPath: "blockchain.scripthash.get_first_use",
            expectedParameters: [scriptHash]
        )
        try assertEndpoint(
            .blockchain.scriptHash.getHistory(
                scriptHash: scriptHash,
                fromHeight: 5,
                toHeight: 10,
                shouldIncludeUnconfirmed: true
            ),
            expectedPath: "blockchain.scripthash.get_history",
            expectedParameters: [scriptHash, 5, 10]
        )
        try assertEndpoint(
            .blockchain.scriptHash.getMempool(scriptHash: scriptHash),
            expectedPath: "blockchain.scripthash.get_mempool",
            expectedParameters: [scriptHash]
        )
        try assertEndpoint(
            .blockchain.scriptHash.listUnspent(scriptHash: scriptHash, tokenFilter: .only),
            expectedPath: "blockchain.scripthash.listunspent",
            expectedParameters: [scriptHash, "tokens_only"]
        )
        try assertEndpoint(
            .blockchain.scriptHash.subscribe(scriptHash: scriptHash),
            expectedPath: "blockchain.scripthash.subscribe",
            expectedParameters: [scriptHash]
        )
        try assertEndpoint(
            .blockchain.scriptHash.unsubscribe(scriptHash: scriptHash),
            expectedPath: "blockchain.scripthash.unsubscribe",
            expectedParameters: [scriptHash]
        )

        try assertEndpoint(
            .blockchain.address.getBalance(address: address, tokenFilter: .exclude),
            expectedPath: "blockchain.address.get_balance",
            expectedParameters: [address, "exclude_tokens"]
        )
        try assertEndpoint(
            .blockchain.address.getFirstUse(address: address),
            expectedPath: "blockchain.address.get_first_use",
            expectedParameters: [address]
        )
        try assertEndpoint(
            .blockchain.address.getHistory(
                address: address,
                fromHeight: 7,
                toHeight: 9,
                shouldIncludeUnconfirmed: true
            ),
            expectedPath: "blockchain.address.get_history",
            expectedParameters: [address, 7, 9]
        )
        try assertEndpoint(
            .blockchain.address.getMempool(address: address),
            expectedPath: "blockchain.address.get_mempool",
            expectedParameters: [address]
        )
        try assertEndpoint(
            .blockchain.address.getScriptHash(address: address),
            expectedPath: "blockchain.address.get_scripthash",
            expectedParameters: [address]
        )
        try assertEndpoint(
            .blockchain.address.listUnspent(address: address, tokenFilter: .include),
            expectedPath: "blockchain.address.listunspent",
            expectedParameters: [address, "include_tokens"]
        )
        try assertEndpoint(
            .blockchain.address.subscribe(address: address),
            expectedPath: "blockchain.address.subscribe",
            expectedParameters: [address]
        )
        try assertEndpoint(
            .blockchain.address.unsubscribe(address: address),
            expectedPath: "blockchain.address.unsubscribe",
            expectedParameters: [address]
        )
    }

    @Test("Typed API endpoints encode blockchain core requests")
    func encodeTypedBlockchainCoreEndpoints() throws {
        try assertEndpoint(.blockchain.estimateFee(numberOfBlocks: 6), expectedPath: "blockchain.estimatefee", expectedParameters: [6])
        try assertEndpoint(.blockchain.relayFee, expectedPath: "blockchain.relayfee", expectedParameters: [])
        try assertEndpoint(.blockchain.block.header(height: 100), expectedPath: "blockchain.block.header", expectedParameters: [100, 0])
        try assertEndpoint(
            .blockchain.block.headers(startHeight: 200, count: 10, checkpointHeight: 777),
            expectedPath: "blockchain.block.headers",
            expectedParameters: [200, 10, 777]
        )
        try assertEndpoint(.blockchain.header.get(blockHash: "abc"), expectedPath: "blockchain.header.get", expectedParameters: ["abc"])
        try assertEndpoint(.blockchain.headers.getTip, expectedPath: "blockchain.headers.get_tip", expectedParameters: [])
        try assertEndpoint(.blockchain.headers.subscribe, expectedPath: "blockchain.headers.subscribe", expectedParameters: [])
        try assertEndpoint(.blockchain.headers.unsubscribe, expectedPath: "blockchain.headers.unsubscribe", expectedParameters: [])
        try assertEndpoint(
            .blockchain.utxo.getInfo(transactionHash: "ee", outputIndex: 7),
            expectedPath: "blockchain.utxo.get_info",
            expectedParameters: ["ee", 7]
        )
    }

    @Test("Typed API endpoints encode transaction requests")
    func encodeTypedTransactionEndpoints() throws {
        try assertEndpoint(
            .blockchain.transaction.broadcast(rawTransaction: "00"),
            expectedPath: "blockchain.transaction.broadcast",
            expectedParameters: ["00"]
        )
        try assertEndpoint(
            .blockchain.transaction.get(transactionHash: "aa"),
            expectedPath: "blockchain.transaction.get",
            expectedParameters: ["aa", false]
        )
        try assertEndpoint(
            .blockchain.transaction.getVerbose(transactionHash: "aa"),
            expectedPath: "blockchain.transaction.get",
            expectedParameters: ["aa", true]
        )
        try assertEndpoint(
            .blockchain.transaction.getConfirmedBlockHash(transactionHash: "aa", shouldIncludeHeader: true),
            expectedPath: "blockchain.transaction.get_confirmed_blockhash",
            expectedParameters: ["aa", true]
        )
        try assertEndpoint(
            .blockchain.transaction.getHeight(transactionHash: "aa"),
            expectedPath: "blockchain.transaction.get_height",
            expectedParameters: ["aa"]
        )
        try assertEndpoint(
            .blockchain.transaction.getMerkle(transactionHash: "aa", height: 123),
            expectedPath: "blockchain.transaction.get_merkle",
            expectedParameters: ["aa", 123]
        )
        try assertEndpoint(
            .blockchain.transaction.idFromPos(
                blockHeight: 2,
                transactionPosition: 3,
                shouldIncludeMerkleProof: false
            ),
            expectedPath: "blockchain.transaction.id_from_pos",
            expectedParameters: [2, 3, false]
        )
        try assertEndpoint(
            .blockchain.transaction.subscribe(transactionHash: "bb"),
            expectedPath: "blockchain.transaction.subscribe",
            expectedParameters: ["bb"]
        )
        try assertEndpoint(
            .blockchain.transaction.unsubscribe(transactionHash: "bb"),
            expectedPath: "blockchain.transaction.unsubscribe",
            expectedParameters: ["bb"]
        )
        try assertEndpoint(
            .blockchain.transaction.dsProof.get(transactionHash: "cc"),
            expectedPath: "blockchain.transaction.dsproof.get",
            expectedParameters: ["cc"]
        )
        try assertEndpoint(
            .blockchain.transaction.dsProof.list,
            expectedPath: "blockchain.transaction.dsproof.list",
            expectedParameters: []
        )
        try assertEndpoint(
            .blockchain.transaction.dsProof.subscribe(transactionHash: "dd"),
            expectedPath: "blockchain.transaction.dsproof.subscribe",
            expectedParameters: ["dd"]
        )
        try assertEndpoint(
            .blockchain.transaction.dsProof.unsubscribe(transactionHash: "dd"),
            expectedPath: "blockchain.transaction.dsproof.unsubscribe",
            expectedParameters: ["dd"]
        )
    }
}

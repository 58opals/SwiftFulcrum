// FulcrumMethodRequestEncodingValidator~APIBlockchainEndpoints.swift

import Testing
@testable import SwiftFulcrum

extension FulcrumMethodRequestEncodingValidator {
    @Test("Typed API endpoints encode blockchain core requests")
    func encodeTypedBlockchainCoreEndpoints() throws {
        try assertEndpoint(SwiftFulcrum.API.blockchain.estimateFee(numberOfBlocks: 6), expectedPath: "blockchain.estimatefee", expectedParameters: [6])
        try assertEndpoint(SwiftFulcrum.API.blockchain.relayFee, expectedPath: "blockchain.relayfee", expectedParameters: [])
        try assertEndpoint(SwiftFulcrum.API.blockchain.block.header(height: 100), expectedPath: "blockchain.block.header", expectedParameters: [100, 0])
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.block.headers(startHeight: 200, count: 10, checkpointHeight: 777),
            expectedPath: "blockchain.block.headers",
            expectedParameters: [200, 10, 777]
        )
        try assertEndpoint(SwiftFulcrum.API.blockchain.header.lookup(blockHash: "abc"), expectedPath: "blockchain.header.get", expectedParameters: ["abc"])
        try assertEndpoint(SwiftFulcrum.API.blockchain.headers.tip, expectedPath: "blockchain.headers.get_tip", expectedParameters: [])
        try assertEndpoint(SwiftFulcrum.API.blockchain.headers.subscribe, expectedPath: "blockchain.headers.subscribe", expectedParameters: [])
        try assertEndpoint(SwiftFulcrum.API.blockchain.headers.unsubscribe, expectedPath: "blockchain.headers.unsubscribe", expectedParameters: [])
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.utxo.info(transactionHash: "ee", outputIndex: 7),
            expectedPath: "blockchain.utxo.get_info",
            expectedParameters: ["ee", 7]
        )
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.utxo.info(transactionHash: "ee", outputIndex: 65_536),
            expectedPath: "blockchain.utxo.get_info",
            expectedParameters: ["ee", 65_536]
        )
    }

    @Test("Typed API endpoints encode transaction requests")
    func encodeTypedTransactionEndpoints() throws {
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.transaction.broadcast(rawTransaction: "00"),
            expectedPath: "blockchain.transaction.broadcast",
            expectedParameters: ["00"]
        )
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.transaction.raw(transactionHash: "aa"),
            expectedPath: "blockchain.transaction.get",
            expectedParameters: ["aa", false]
        )
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.transaction.verbose(transactionHash: "aa"),
            expectedPath: "blockchain.transaction.get",
            expectedParameters: ["aa", true]
        )
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.transaction.confirmedBlockHash(transactionHash: "aa", shouldIncludeHeader: true),
            expectedPath: "blockchain.transaction.get_confirmed_blockhash",
            expectedParameters: ["aa", true]
        )
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.transaction.height(transactionHash: "aa"),
            expectedPath: "blockchain.transaction.get_height",
            expectedParameters: ["aa"]
        )
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.transaction.merkle(transactionHash: "aa", height: 123),
            expectedPath: "blockchain.transaction.get_merkle",
            expectedParameters: ["aa", 123]
        )
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.transaction.idFromPos(
                blockHeight: 2,
                transactionPosition: 3,
                shouldIncludeMerkleProof: false
            ),
            expectedPath: "blockchain.transaction.id_from_pos",
            expectedParameters: [2, 3, false]
        )
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.transaction.subscribe(transactionHash: "bb"),
            expectedPath: "blockchain.transaction.subscribe",
            expectedParameters: ["bb"]
        )
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.transaction.unsubscribe(transactionHash: "bb"),
            expectedPath: "blockchain.transaction.unsubscribe",
            expectedParameters: ["bb"]
        )
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.transaction.dsProof.lookup(transactionHash: "cc"),
            expectedPath: "blockchain.transaction.dsproof.get",
            expectedParameters: ["cc"]
        )
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.transaction.dsProof.list,
            expectedPath: "blockchain.transaction.dsproof.list",
            expectedParameters: []
        )
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.transaction.dsProof.subscribe(transactionHash: "dd"),
            expectedPath: "blockchain.transaction.dsproof.subscribe",
            expectedParameters: ["dd"]
        )
        try assertEndpoint(
            SwiftFulcrum.API.blockchain.transaction.dsProof.unsubscribe(transactionHash: "dd"),
            expectedPath: "blockchain.transaction.dsproof.unsubscribe",
            expectedParameters: ["dd"]
        )
    }
}

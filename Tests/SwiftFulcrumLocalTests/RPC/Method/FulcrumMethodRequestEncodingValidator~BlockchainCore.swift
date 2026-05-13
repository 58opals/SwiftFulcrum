// FulcrumMethodRequestEncodingValidator~BlockchainCore.swift

import Foundation
import Testing
@testable import SwiftFulcrum

extension FulcrumMethodRequestEncodingValidator {
    @Test("Preserves protocol-aligned get* Fulcrum method path strings")
    func preserveProtocolAlignedGetMethodPaths() {
        #expect(
            SwiftFulcrum.RPC.Method.blockchain(.header(.get(blockHash: "abc"))).path
            == "blockchain.header.get"
        )
        #expect(
            SwiftFulcrum.RPC.Method.blockchain(.headers(.getTip)).path
            == "blockchain.headers.get_tip"
        )
        #expect(
            SwiftFulcrum.RPC.Method.blockchain(.address(.getBalance(address: "addr", tokenFilter: nil))).path
            == "blockchain.address.get_balance"
        )
        #expect(
            SwiftFulcrum.RPC.Method.blockchain(.scripthash(.getHistory(
                scripthash: "hash",
                fromHeight: nil,
                toHeight: nil,
                shouldIncludeUnconfirmed: false
            ))).path
            == "blockchain.scripthash.get_history"
        )
        #expect(
            SwiftFulcrum.RPC.Method.blockchain(.transaction(.get(transactionHash: "tx", isVerbose: false))).path
            == "blockchain.transaction.get"
        )
        #expect(
            SwiftFulcrum.RPC.Method.blockchain(.transaction(.getConfirmedBlockHash(
                transactionHash: "tx",
                shouldIncludeHeader: false
            ))).path
            == "blockchain.transaction.get_confirmed_blockhash"
        )
    }

    @Test("Encodes block.header without a checkpoint proof by sending cp_height zero")
    func encodeBlockHeaderWithoutCheckpointProof() throws {
        try assertRequest(
            .blockchain(.block(.header(height: 100, checkpointHeight: nil))),
            expectedPath: SwiftFulcrum.RPC.Method.blockchain(.block(.header(height: 0, checkpointHeight: nil))).path,
            expectedParameters: [100, 0]
        )

        let overflowHeaderObject = try requestObject(
            for: .blockchain(.block(.header(height: UInt.max, checkpointHeight: nil)))
        )
        let overflowHeaderParameters = try #require(overflowHeaderObject["params"] as? [Any])
        #expect(overflowHeaderParameters.count == 2)
        #expect((overflowHeaderParameters[0] as? NSNumber)?.uint64Value == UInt64.max)
        #expect((overflowHeaderParameters[1] as? NSNumber)?.uint64Value == 0)
    }

    @Test("Encodes remaining blockchain request variants")
    func encodeRemainingBlockchainRequests() throws {
        try assertRequest(
            .blockchain(.estimateFee(numberOfBlocks: 6)),
            expectedPath: SwiftFulcrum.RPC.Method.blockchain(.estimateFee(numberOfBlocks: 0)).path,
            expectedParameters: [6]
        )
        try assertRequest(
            .blockchain(.relayFee),
            expectedPath: SwiftFulcrum.RPC.Method.blockchain(.relayFee).path,
            expectedParameters: []
        )
        try assertRequest(
            .blockchain(.block(.header(height: 100, checkpointHeight: nil))),
            expectedPath: SwiftFulcrum.RPC.Method.blockchain(.block(.header(height: 0, checkpointHeight: nil))).path,
            expectedParameters: [100, 0]
        )
        try assertRequest(
            .blockchain(.block(.header(height: 100, checkpointHeight: 500))),
            expectedPath: SwiftFulcrum.RPC.Method.blockchain(.block(.header(height: 0, checkpointHeight: nil))).path,
            expectedParameters: [100, 500]
        )
        let overflowHeaderObject = try requestObject(
            for: .blockchain(.block(.header(height: UInt.max, checkpointHeight: nil)))
        )
        #expect(
            overflowHeaderObject["method"] as? String
            == SwiftFulcrum.RPC.Method.blockchain(.block(.header(height: 0, checkpointHeight: nil))).path
        )
        let overflowHeaderParameters = try #require(overflowHeaderObject["params"] as? [Any])
        #expect(overflowHeaderParameters.count == 2)
        #expect((overflowHeaderParameters[0] as? NSNumber)?.uint64Value == UInt64.max)
        #expect((overflowHeaderParameters[1] as? NSNumber)?.uint64Value == 0)
        try assertRequest(
            .blockchain(.block(.headers(startHeight: 200, count: 10, checkpointHeight: nil))),
            expectedPath: SwiftFulcrum.RPC.Method.blockchain(.block(.headers(startHeight: 0, count: 0, checkpointHeight: nil))).path,
            expectedParameters: [200, 10, 0]
        )
        try assertRequest(
            .blockchain(.block(.headers(startHeight: 200, count: 10, checkpointHeight: 777))),
            expectedPath: SwiftFulcrum.RPC.Method.blockchain(.block(.headers(startHeight: 0, count: 0, checkpointHeight: nil))).path,
            expectedParameters: [200, 10, 777]
        )
        try assertRequest(
            .blockchain(.header(.get(blockHash: "abc"))),
            expectedPath: SwiftFulcrum.RPC.Method.blockchain(.header(.get(blockHash: ""))).path,
            expectedParameters: ["abc"]
        )
        try assertRequest(
            .blockchain(.headers(.getTip)),
            expectedPath: SwiftFulcrum.RPC.Method.blockchain(.headers(.getTip)).path,
            expectedParameters: []
        )
        try assertRequest(
            .blockchain(.headers(.subscribe)),
            expectedPath: SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe)).path,
            expectedParameters: []
        )
        try assertRequest(
            .blockchain(.headers(.unsubscribe)),
            expectedPath: SwiftFulcrum.RPC.Method.blockchain(.headers(.unsubscribe)).path,
            expectedParameters: []
        )
        try assertRequest(
            .blockchain(.transaction(.broadcast(rawTransaction: "00"))),
            expectedPath: SwiftFulcrum.RPC.Method.blockchain(.transaction(.broadcast(rawTransaction: ""))).path,
            expectedParameters: ["00"]
        )
        try assertRequest(
            .blockchain(.transaction(.get(transactionHash: "aa", isVerbose: true))),
            expectedPath: SwiftFulcrum.RPC.Method.blockchain(.transaction(.get(transactionHash: "", isVerbose: false))).path,
            expectedParameters: ["aa", true]
        )
        try assertRequest(
            .blockchain(.transaction(.getConfirmedBlockHash(transactionHash: "aa", shouldIncludeHeader: true))),
            expectedPath: SwiftFulcrum.RPC.Method.blockchain(.transaction(.getConfirmedBlockHash(transactionHash: "", shouldIncludeHeader: false))).path,
            expectedParameters: ["aa", true]
        )
        try assertRequest(
            .blockchain(.transaction(.getHeight(transactionHash: "aa"))),
            expectedPath: SwiftFulcrum.RPC.Method.blockchain(.transaction(.getHeight(transactionHash: ""))).path,
            expectedParameters: ["aa"]
        )
        try assertRequest(
            .blockchain(.transaction(.getMerkle(transactionHash: "aa", height: 123))),
            expectedPath: SwiftFulcrum.RPC.Method.blockchain(.transaction(.getMerkle(transactionHash: "", height: 0))).path,
            expectedParameters: ["aa", 123]
        )
        try assertRequest(
            .blockchain(.transaction(.idFromPos(blockHeight: 2, transactionPosition: 3, shouldIncludeMerkleProof: false))),
            expectedPath: SwiftFulcrum.RPC.Method.blockchain(.transaction(.idFromPos(blockHeight: 0, transactionPosition: 0, shouldIncludeMerkleProof: false))).path,
            expectedParameters: [2, 3, false]
        )
        try assertRequest(
            .blockchain(.transaction(.subscribe(transactionHash: "bb"))),
            expectedPath: SwiftFulcrum.RPC.Method.blockchain(.transaction(.subscribe(transactionHash: ""))).path,
            expectedParameters: ["bb"]
        )
        try assertRequest(
            .blockchain(.transaction(.unsubscribe(transactionHash: "bb"))),
            expectedPath: SwiftFulcrum.RPC.Method.blockchain(.transaction(.unsubscribe(transactionHash: ""))).path,
            expectedParameters: ["bb"]
        )
        try assertRequest(
            .blockchain(.transaction(.dsProof(.get(transactionHash: "cc")))),
            expectedPath: SwiftFulcrum.RPC.Method.blockchain(.transaction(.dsProof(.get(transactionHash: "")))).path,
            expectedParameters: ["cc"]
        )
        try assertRequest(
            .blockchain(.transaction(.dsProof(.list))),
            expectedPath: SwiftFulcrum.RPC.Method.blockchain(.transaction(.dsProof(.list))).path,
            expectedParameters: []
        )
        try assertRequest(
            .blockchain(.transaction(.dsProof(.subscribe(transactionHash: "dd")))),
            expectedPath: SwiftFulcrum.RPC.Method.blockchain(.transaction(.dsProof(.subscribe(transactionHash: "")))).path,
            expectedParameters: ["dd"]
        )
        try assertRequest(
            .blockchain(.transaction(.dsProof(.unsubscribe(transactionHash: "dd")))),
            expectedPath: SwiftFulcrum.RPC.Method.blockchain(.transaction(.dsProof(.unsubscribe(transactionHash: "")))).path,
            expectedParameters: ["dd"]
        )
        try assertRequest(
            .blockchain(.utxo(.getInfo(transactionHash: "ee", outputIndex: 7))),
            expectedPath: SwiftFulcrum.RPC.Method.blockchain(.utxo(.getInfo(transactionHash: "", outputIndex: 0))).path,
            expectedParameters: ["ee", 7]
        )
        try assertRequest(
            .blockchain(.utxo(.getInfo(transactionHash: "ee", outputIndex: 65_536))),
            expectedPath: SwiftFulcrum.RPC.Method.blockchain(.utxo(.getInfo(transactionHash: "", outputIndex: 0))).path,
            expectedParameters: ["ee", 65_536]
        )
    }
}

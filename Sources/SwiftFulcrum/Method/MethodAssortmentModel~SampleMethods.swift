// MethodAssortmentModel~SampleMethods.swift

extension MethodAssortmentModel {
    static var sampleMethods: [SwiftFulcrum.RPC.Method] {
        guard let minimumVersion = SwiftFulcrum.ProtocolVersion(string: "1.4"),
              let maximumVersion = SwiftFulcrum.ProtocolVersion(string: "1.6.0"),
              let versionRange = SwiftFulcrum.ProtocolVersion.Range(min: minimumVersion, max: maximumVersion) else {
            preconditionFailure("Sample protocol versions must be valid")
        }

        return [
            // ServerModel
            .server(.ping),
            .server(.version(clientName: "Sample Client",
                             protocolNegotiation: .init(range: versionRange))),
            .server(.features),

            // BlockchainModel
            .blockchain(
                .estimateFee(numberOfBlocks: 6)),
            .blockchain(
                .relayFee),

            // BlockchainModel.ScriptHash
            .blockchain(
                .scripthash(
                    .getBalance(scripthash: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
                                tokenFilter: .include))),
            .blockchain(
                .scripthash(
                    .getFirstUse(scripthash: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"))),
            .blockchain(
                .scripthash(
                    .getHistory(scripthash: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
                                fromHeight: nil,
                                toHeight: nil,
                                shouldIncludeUnconfirmed: true))),
            .blockchain(
                .scripthash(
                    .getMempool(scripthash: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"))),
            .blockchain(
                .scripthash(
                    .listUnspent(scripthash: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
                                 tokenFilter: .include))),
            .blockchain(
                .scripthash(
                    .subscribe(scripthash: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"))),
            .blockchain(
                .scripthash(
                    .unsubscribe(scripthash: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"))),


            // BlockchainModel.Address
            .blockchain(
                .address(
                    .getBalance(address: "qrmydkpmlgvxrafjv7rpdm4unlcdfnljmqss98ytuq",
                                tokenFilter: .include))),
            .blockchain(
                .address(
                    .getFirstUse(address: "qrmydkpmlgvxrafjv7rpdm4unlcdfnljmqss98ytuq"))),
            .blockchain(
                .address(
                    .getHistory(address: "qrmydkpmlgvxrafjv7rpdm4unlcdfnljmqss98ytuq",
                                fromHeight: nil,
                                toHeight: nil,
                                shouldIncludeUnconfirmed: true))),
            .blockchain(
                .address(
                    .getMempool(address: "qrmydkpmlgvxrafjv7rpdm4unlcdfnljmqss98ytuq"))),
            .blockchain(
                .address(
                    .getScriptHash(address: "qrmydkpmlgvxrafjv7rpdm4unlcdfnljmqss98ytuq"))),
            .blockchain(
                .address(
                    .listUnspent(address: "qrmydkpmlgvxrafjv7rpdm4unlcdfnljmqss98ytuq",
                                 tokenFilter: .include))),
            .blockchain(
                .address(
                    .subscribe(address: "qrmydkpmlgvxrafjv7rpdm4unlcdfnljmqss98ytuq"))),
            .blockchain(
                .address(
                    .unsubscribe(address: "qrmydkpmlgvxrafjv7rpdm4unlcdfnljmqss98ytuq"))),

            // BlockchainModel.Block
            .blockchain(
                .block(
                    .header(height: 1,
                            checkpointHeight: 0))),
            .blockchain(
                .block(
                    .headers(startHeight: 1,
                             count: 10,
                             checkpointHeight: 0))),

            // BlockchainModel.HeaderModel
            .blockchain(
                .header(
                    .get(blockHash: "0000000000000000029c2784e7453617ea6d8e73cbc91b293d06cf41cf3a5286"))),

            // BlockchainModel.Headers
            .blockchain(
                .headers(
                    .getTip)),
            .blockchain(
                .headers(
                    .subscribe)),
            .blockchain(
                .headers(
                    .unsubscribe)),

            // BlockchainModel.Transaction
            .blockchain(
                .transaction(
                    .broadcast(rawTransaction: "rawTx"))),
            .blockchain(
                .transaction(
                    .get(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1",
                         isVerbose: true))),
            .blockchain(
                .transaction(
                    .getConfirmedBlockHash(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1",
                                           shouldIncludeHeader: true))),
            .blockchain(
                .transaction(
                    .getHeight(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1"))),
            .blockchain(
                .transaction(
                    .getMerkle(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1"))),
            .blockchain(
                .transaction(
                    .idFromPos(blockHeight: 1,
                               transactionPosition: 0,
                               shouldIncludeMerkleProof: true))),
            .blockchain(
                .transaction(
                    .subscribe(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1"))),
            .blockchain(
                .transaction(
                    .unsubscribe(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1"))),

            // BlockchainModel.Transaction.DSProof
            .blockchain(
                .transaction(
                    .dsProof(
                        .get(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1")))),
            .blockchain(
                .transaction(
                    .dsProof(
                        .list))),
            .blockchain(
                .transaction(
                    .dsProof(
                        .subscribe(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1")))),
            .blockchain(
                .transaction(
                    .dsProof(
                        .unsubscribe(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1")))),

            // BlockchainModel.UTXO
            .blockchain(
                .utxo(
                    .getInfo(transactionHash: "1452186edb3b7f8a0e64fefaf3c3879272e52bdccdbc329de8987e44f3f5bfd1",
                             outputIndex: 0))),

            // MempoolModel
            .mempool(.getInfo),
            .mempool(.getFeeHistogram)
        ]
    }
}

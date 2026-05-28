// Response.Result.Blockchain~Validation.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain {
    static let blockHashCharacterLength = 64
    static let blockHeaderCharacterLength = 160
    static let doubleSpendProofIdentifierCharacterLength = 64
    static let scriptHashCharacterLength = 64
    static let transactionHashCharacterLength = 64

    static func validateBlockHash(_ hash: String) throws {
        try validateHex(hash, expectedLength: blockHashCharacterLength, description: "block hash")
    }

    static func validateBlockHeader(_ header: String) throws {
        try validateHex(header, expectedLength: blockHeaderCharacterLength, description: "block header")
    }

    static func validateBlockHeaders(_ headers: [String]) throws {
        for header in headers {
            try validateBlockHeader(header)
        }
    }

    static func validateDoubleSpendProofIdentifier(_ proofIdentifier: String) throws {
        try validateHex(
            proofIdentifier,
            expectedLength: doubleSpendProofIdentifierCharacterLength,
            description: "double-spend proof identifier"
        )
    }

    static func validateScriptHash(_ hash: String) throws {
        try validateHex(hash, expectedLength: scriptHashCharacterLength, description: "script hash")
    }

    static func validateTransactionHash(_ hash: String) throws {
        try validateHex(hash, expectedLength: transactionHashCharacterLength, description: "transaction hash")
    }

    static func validateHexString(_ value: String, description: String) throws {
        guard value.count.isMultiple(of: 2) else {
            throw ResponseResultDecodeError.unexpectedFormat(
                "Expected \(description) to contain an even number of hex characters"
            )
        }

        try validateHexDigits(value, description: description)
    }

    static func validateNonEmptyHexString(_ value: String, description: String) throws {
        guard !value.isEmpty else {
            throw ResponseResultDecodeError.unexpectedFormat("Expected \(description) to be non-empty")
        }

        try validateHexString(value, description: description)
    }

    static func validateTransactionHashes(_ hashes: [String], description: String = "transaction hash") throws {
        for hash in hashes {
            try validateHex(hash, expectedLength: transactionHashCharacterLength, description: description)
        }
    }

    static func validateMerkleHashes(_ hashes: [String]) throws {
        try validateTransactionHashes(hashes, description: "merkle proof hash")
    }

    static func validateMerkleRoot(_ hash: String) throws {
        try validateHex(hash, expectedLength: transactionHashCharacterLength, description: "merkle root hash")
    }

    static func validateMempoolTransactionHeight(_ height: Int) throws {
        guard height == -1 || height == 0 else {
            throw ResponseResultDecodeError.unexpectedFormat("Expected mempool transaction height to be -1 or 0")
        }
    }

    private static func validateHex(_ value: String, expectedLength: Int, description: String) throws {
        guard value.count == expectedLength else {
            throw ResponseResultDecodeError.unexpectedFormat(
                "Expected \(description) to be exactly \(expectedLength) hex characters"
            )
        }

        try validateHexDigits(value, description: description)
    }

    private static func validateHexDigits(_ value: String, description: String) throws {
        guard value.utf8.allSatisfy(Self.isHexDigit) else {
            throw ResponseResultDecodeError.unexpectedFormat(
                "Expected \(description) to contain only hex characters"
            )
        }
    }

    private static func isHexDigit(_ byte: UInt8) -> Bool {
        (48 ... 57).contains(byte) || (65 ... 70).contains(byte) || (97 ... 102).contains(byte)
    }
}

// Response.Result.Blockchain~Validation.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain {
    static let blockHashCharacterLength = 64
    static let blockHeaderCharacterLength = 160
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

    static func validateScriptHash(_ hash: String) throws {
        try validateHex(hash, expectedLength: scriptHashCharacterLength, description: "script hash")
    }

    static func validateTransactionHash(_ hash: String) throws {
        try validateHex(hash, expectedLength: transactionHashCharacterLength, description: "transaction hash")
    }

    static func validateMerkleHashes(_ hashes: [String]) throws {
        for hash in hashes {
            try validateHex(hash, expectedLength: transactionHashCharacterLength, description: "merkle proof hash")
        }
    }

    private static func validateHex(_ value: String, expectedLength: Int, description: String) throws {
        guard value.count == expectedLength else {
            throw ResponseResultDecodeError.unexpectedFormat(
                "Expected \(description) to be exactly \(expectedLength) hex characters"
            )
        }

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

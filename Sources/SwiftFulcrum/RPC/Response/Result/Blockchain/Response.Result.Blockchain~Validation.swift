// Response.Result.Blockchain~Validation.swift

import Foundation

extension SwiftFulcrum.Response.Blockchain {
    static let blockHashCharacterLength = 64
    static let blockHeaderCharacterLength = 160
    static let transactionHashCharacterLength = 64

    static func validateBlockHashLength(_ hash: String) throws {
        guard hash.count == blockHashCharacterLength else {
            throw ResponseResultDecodeError.unexpectedFormat(
                "Expected block hash to be exactly \(blockHashCharacterLength) hex characters"
            )
        }
    }

    static func validateBlockHeaderLength(_ header: String) throws {
        guard header.count == blockHeaderCharacterLength else {
            throw ResponseResultDecodeError.unexpectedFormat(
                "Expected block header to be exactly \(blockHeaderCharacterLength) hex characters"
            )
        }
    }

    static func validateBlockHeaderLengths(_ headers: [String]) throws {
        for header in headers {
            try validateBlockHeaderLength(header)
        }
    }

    static func validateTransactionHashLength(_ hash: String) throws {
        guard hash.count == transactionHashCharacterLength else {
            throw ResponseResultDecodeError.unexpectedFormat(
                "Expected transaction hash to be exactly \(transactionHashCharacterLength) hex characters"
            )
        }
    }

    static func validateMerkleHashLengths(_ hashes: [String]) throws {
        for hash in hashes {
            guard hash.count == transactionHashCharacterLength else {
                throw ResponseResultDecodeError.unexpectedFormat(
                    "Expected merkle proof hash to be exactly \(transactionHashCharacterLength) hex characters"
                )
            }
        }
    }
}

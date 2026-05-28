// CashTokensCapabilityValidator.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct CashTokensCapabilityValidator {
    @Test("Decodes CashTokens capability from a string")
    func decodeNFTCapabilityFromString() throws {
        let serializedPayload = makeTokenDataObjectJSONString()
        let serializedData = try #require(serializedPayload.data(using: .utf8))

        let decoded = try JSONDecoder().decode(SwiftFulcrum.CashTokens.TokenData.self, from: serializedData)
        let nonFungibleToken = try #require(decoded.nft)

        #expect(nonFungibleToken.capability == .none)
    }

    @Test(
        "Rejects malformed CashTokens category identifiers",
        arguments: [
            "token-category",
            String(repeating: "a", count: 63)
        ]
    )
    func rejectMalformedCategoryIdentifiers(_ category: String) throws {
        let serializedPayload = makeTokenDataObjectJSONString(category: category)
        try expectTokenDataDecodeFailure(serializedPayload)
    }

    @Test(
        "Rejects malformed CashTokens amounts",
        arguments: [
            ("empty amount", ""),
            ("negative amount", "-1"),
            ("fractional amount", "1.5"),
            ("non-ASCII amount", "１２"),
            ("overflow amount", "9223372036854775808")
        ]
    )
    func rejectMalformedAmounts(_ caseDescription: String, _ amount: String) throws {
        let serializedPayload = makeTokenDataObjectJSONString(amount: amount)
        try expectTokenDataDecodeFailure(serializedPayload)
    }

    @Test(
        "Rejects malformed CashTokens NFT commitments",
        arguments: [
            ("non-hex commitment", "commitment"),
            ("odd-length commitment", "abc"),
            ("oversized commitment", String(repeating: "a", count: 82))
        ]
    )
    func rejectMalformedNFTCommitments(_ caseDescription: String, _ commitment: String) throws {
        let serializedPayload = makeTokenDataObjectJSONString(commitment: commitment)
        try expectTokenDataDecodeFailure(serializedPayload)
    }

    @Test("Decodes list unspent items with CashTokens data")
    func decodeListUnspentResponseWithTokenData() throws {
        let responseIdentifier = UUID()
        let serializedResponse = """
        {
          "jsonrpc": "2.0",
          "id": "\(responseIdentifier.uuidString)",
          "result": [
            {
              "height": 0,
              "token_data": \(makeTokenDataObjectJSONString()),
              "tx_hash": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
              "tx_pos": 0,
              "value": 546
            }
          ]
        }
        """
        let serializedData = try #require(serializedResponse.data(using: .utf8))

        let decodedResponse = try serializedData.decode(
            SwiftFulcrum.Response.Blockchain.Address.ListUnspent.self,
            context: .init(methodPath: "blockchain.address.listunspent")
        )
        let firstItem = try #require(decodedResponse.items.first)
        let tokenData = try #require(firstItem.tokenData)
        let nonFungibleToken = try #require(tokenData.nft)

        #expect(firstItem.transactionHash == "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef")
        #expect(nonFungibleToken.capability == .none)
    }

    private func makeTokenDataObjectJSONString(
        amount: String = "0",
        category: String = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
        commitment: String = ""
    ) -> String {
        """
        {
          "amount": "\(amount)",
          "category": "\(category)",
          "nft": { "capability": "none", "commitment": "\(commitment)" }
        }
        """
    }

    private func expectTokenDataDecodeFailure(_ serializedPayload: String) throws {
        let serializedData = try #require(serializedPayload.data(using: .utf8))

        #expect(throws: ResponseResultDecodeError.self) {
            _ = try JSONDecoder().decode(SwiftFulcrum.CashTokens.TokenData.self, from: serializedData)
        }
    }
}

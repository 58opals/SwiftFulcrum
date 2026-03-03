import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct CashTokensCapabilityValidator {
    @Test("Decodes CashTokens capability from a string")
    func decodeCapabilityFromString() throws {
        let serializedPayload = """
        {
          "amount": "0",
          "category": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
          "nft": { "capability": "none", "commitment": "" }
        }
        """
        let serializedData = try #require(serializedPayload.data(using: .utf8))

        let decoded = try JSONDecoder().decode(FulcrumMethodRequest.BlockchainModel.CashTokens.JSON.self, from: serializedData)
        let nonFungibleToken = try #require(decoded.nft)

        #expect(nonFungibleToken.capability == .none)
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
              "token_data": {
                "amount": "0",
                "category": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
                "nft": { "capability": "none", "commitment": "" }
              },
              "tx_hash": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
              "tx_pos": 0,
              "value": 546
            }
          ]
        }
        """
        let serializedData = try #require(serializedResponse.data(using: .utf8))

        let decodedResponse = try JSONDecoder().decode(
            FulcrumResponse.JSONRPCModel.Generic<FulcrumResponse.JSONRPCModel.Result.Blockchain.Address.ListUnspent>.self,
            from: serializedData
        )
        let listUnspentItems = try #require(decodedResponse.result)
        let firstItem = try #require(listUnspentItems.first)
        let tokenData = try #require(firstItem.token_data)
        let nonFungibleToken = try #require(tokenData.nft)

        #expect(firstItem.tx_hash == "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef")
        #expect(nonFungibleToken.capability == .none)
    }
}

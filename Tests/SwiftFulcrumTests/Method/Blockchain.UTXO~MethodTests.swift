import Testing
import Foundation
@testable import SwiftFulcrum

@Suite("Blockchain UTXO Method Tests")
struct BlockchainUTXODSProofMethodTests {
    let fulcrum: Fulcrum
    
    init() async throws {
        self.fulcrum = try .init()
        
        try await self.fulcrum.start()
    }
}

extension BlockchainUTXODSProofMethodTests {
    @Test func testGetInfo() async {
        do {
            let (id, result) = try await fulcrum.submit(
                method:
                    Method
                    .blockchain(.utxo(.getInfo(transactionHash: "6caa0900477cb17dfbf9d63d034dc6152ebaae97c81bdd1430df43b1f5c445d0",
                                               outputIndex: 1))),
                responseType:
                    Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.UTXO.GetInfo>.self
            )
            
            try #require(UUID(uuidString: id.uuidString) != nil, "The ID \(id.uuidString) is not a valid UUID.")
            
            if let confirmedHeight = result.confirmed_height {
                print("Confirmed height: \(confirmedHeight)")
            } else {
                print("This UTXO is not confirmed yet.")
            }
            print("Value: \(result.value)")
        } catch Fulcrum.Error.resultNotFound(let description) {
            print("Result not found error: \(description)")
        } catch {
            print(error)
        }
    }
}

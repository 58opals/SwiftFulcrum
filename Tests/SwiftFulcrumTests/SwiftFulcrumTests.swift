import XCTest
@testable import SwiftFulcrum

import Foundation
import Combine

final class SwiftFulcrumTests: XCTestCase {
    let fulcrum = SwiftFulcrum(client: .init(webSocket: .init(url: .init(string: "wss://cashnode.bch.ninja:50004")!)))
    
    func testRelayFee() async throws {
        let relayFee = try await fulcrum.requestRelayFee()
        
        let expectedValue = 1e-5
        XCTAssertEqual(relayFee, expectedValue, accuracy: 1e-5, "The relay fee did not match the expected value.")
    }
    
    func testResultBoxObservation() async {
        do {
            let relayFeeID = try await fulcrum.client.sendRequest(from: .blockchain(.relayFee))
            
            var subscribers: Set<AnyCancellable> = .init()
            fulcrum.client.jsonRPC.storage.result.blockchain.relayFee.publisher
                .sink { id in
                    XCTAssertEqual(id, relayFeeID)
                }
                .store(in: &subscribers)
        } catch {
            XCTFail("Failed to store result: \(error)")
        }
    }
}

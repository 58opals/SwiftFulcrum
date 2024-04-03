import XCTest
@testable import SwiftFulcrum

import Foundation
import Combine

final class SwiftFulcrumTests: XCTestCase {
    let fulcrum = SwiftFulcrum(client: .init(webSocket: .init(url: .init(string: "wss://cashnode.bch.ninja:50004")!)))
    
    func testStorageObservation() async {
        do {
            let relayFeeID = try await fulcrum.client.sendRequest(from: .blockchain(.relayFee))
            let estimateFeeID = try await fulcrum.client.sendRequest(from: .blockchain(.estimateFee(1)))
            let subscribeAddressID = try await fulcrum.client.sendRequest(from: .blockchain(.address(.subscribe("someAddress"))))
            
            var subscribers: Set<AnyCancellable> = .init()
            
            fulcrum.client.jsonRPC.storage.result.blockchain.relayFee.publisher
                .sink { id in
                    XCTAssertEqual(id, relayFeeID)
                }
                .store(in: &subscribers)
            
            fulcrum.client.jsonRPC.storage.result.blockchain.estimateFee.publisher
                .sink { id in
                    XCTAssertEqual(id, estimateFeeID)
                }
                .store(in: &subscribers)
            
            fulcrum.client.jsonRPC.storage.result.blockchain.address.subscribe.publisher
                .sink { id in
                    XCTAssertEqual(id, subscribeAddressID)
                }
                .store(in: &subscribers)
            
            fulcrum.client.jsonRPC.storage.result.blockchain.address.notification.publisher
                .sink { id in
                    XCTAssertEqual(id, "someAddress")
                }
                .store(in: &subscribers)
        } catch {
            XCTFail("Failed to store result: \(error)")
        }
    }
}

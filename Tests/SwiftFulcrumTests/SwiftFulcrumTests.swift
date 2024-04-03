import XCTest
@testable import SwiftFulcrum

final class SwiftFulcrumTests: XCTestCase {
    func testClient() async throws {
        let fulcrum = try SwiftFulcrum()
        
        let relayFeeID = try await fulcrum.client.sendRequest(from: .blockchain(.relayFee))
        try await Task.sleep(nanoseconds: 1_000_000_000)
        guard let relayFeeResult = try fulcrum.storage.result.blockchain.relayFee.getResult(for: relayFeeID) else { fatalError() }
        let relayFee = relayFeeResult.fee
        XCTAssertEqual(relayFee, 1e-05)
    }
}

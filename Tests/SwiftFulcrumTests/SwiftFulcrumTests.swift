import XCTest
@testable import SwiftFulcrum

final class SwiftFulcrumTests: XCTestCase {
    let fulcrum = SwiftFulcrum(client: .init(webSocket: .init(url: .init(string: "wss://cashnode.bch.ninja:50004")!)))
    
    func testRelayFee() async throws {
        let relayFee = try await fulcrum.requestRelayFee()
        
        let expectedValue = 1e-5
        XCTAssertEqual(relayFee, expectedValue, accuracy: 1e-5, "The relay fee did not match the expected value.")
    }
}

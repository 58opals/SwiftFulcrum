// ClientInterfaceLocalValidator~EndpointValidation.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ClientInterfaceLocalValidator {
    @Test(
        "Client initialization rejects invalid WebSocket endpoints without echoing raw URLs",
        arguments: [
            "ws:///missing-host",
            "wss://%20"
        ]
    )
    func rejectInvalidWebSocketEndpointWithoutEchoingRawURL(
        invalidEndpointString: String
    ) async throws {
        let invalidEndpoint = try #require(URL(string: invalidEndpointString))

        do {
            let client = try await SwiftFulcrum.Client(connectingTo: invalidEndpoint)
            await client.stop()
            Issue.record("Expected invalid WebSocket endpoint to be rejected during initialization")
        } catch let error as SwiftFulcrum.Client.Error {
            switch error {
            case .client(.invalidURL(let value)):
                #expect(value == "Invalid WebSocket endpoint URL")
                #expect(!value.contains(invalidEndpointString))
                #expect(!value.contains(invalidEndpoint.absoluteString))
            default:
                Issue.record("Unexpected SwiftFulcrum.Client.Error: \(error)")
            }
        } catch {
            Issue.record("Unexpected non-SwiftFulcrum.Client error: \(error)")
        }
    }
}

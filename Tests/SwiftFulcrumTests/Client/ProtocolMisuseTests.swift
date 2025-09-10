import Foundation
import Testing
@testable import SwiftFulcrum

// MARK: - Protocol misuse

@Suite("Protocol misuse")
struct ProtocolMisuseTests {
    @Test
    func submit_with_subscription_method_throws_protocolMismatch() async throws {
        let webSocketURL = URL(string: "wss://example.com")!
        let fulcrum = try Fulcrum(servers: [webSocketURL])
        
        do {
            _ = try await fulcrum.submit(
                method: .blockchain(.headers(.subscribe)),
                responseType: Response.Result.Blockchain.Headers.Subscribe.self
            )
            Issue.record("expected protocolMismatch")
        } catch let error as Fulcrum.Error {
            #expect({
                if case .client(.protocolMismatch(let message)) = error {
                    return message == "submit() cannot be used with subscription methods. Use subscribe(...)."
                }
                return false
            }())
        }
    }
}

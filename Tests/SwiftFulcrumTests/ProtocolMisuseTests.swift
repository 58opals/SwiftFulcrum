import Foundation
import Testing
@testable import SwiftFulcrum

// MARK: - Protocol misuse

@Suite("Protocol misuse")
struct ProtocolMisuseTests {
    @Test
    func submit_with_subscription_method_throws_protocolMismatch() async throws {
        let wsURL = URL(string: "wss://example.com")!
        let fulcrum = try Fulcrum(servers: [wsURL])
        
        do {
            // Submitting a subscription method via submit(...) must fail fast.
            _ = try await fulcrum.submit(
                method: .blockchain(.headers(.subscribe)),
                responseType: Response.Result.Blockchain.Headers.Subscribe.self
            )
            Issue.record("expected protocolMismatch")
        } catch let e as Fulcrum.Error {
            #expect({
                if case .client(.protocolMismatch(let msg)) = e {
                    return msg == "submit() cannot be used with subscription methods. Use subscribe(...)."
                }
                return false
            }())
        }
    }
}

import Foundation
import Testing
@testable import SwiftFulcrum

@Suite(
    "WebSocket.Reconnector",
    .serialized,
    .timeLimit(.minutes(2))
)

struct WebSocketReconnectorTests {
    @Test("retries unhealthy endpoints until a connection succeeds")
    func retriesUntilSuccess() async throws {
        
    }
    
    @Test("retries override URL after initial failure")
    func retriesOverrideUntilSuccess() async throws {
        
    }
    
    @Test("propagates transport errors after exhausting attempts")
    func failsAfterExhaustingAttempts() async throws {
        
    }
    
    @Test("advances through bundled server list when no override URL is provided")
    func iteratesBundledServers() async throws {
        
    }
}

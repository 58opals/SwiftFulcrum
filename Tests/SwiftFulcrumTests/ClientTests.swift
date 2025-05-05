import Testing
import Foundation
@testable import SwiftFulcrum

private extension URL {
    /// Any random main-net Fulcrum endpoint from bundled `servers.json`.
    static func randomFulcrum() throws -> URL {
        guard let url = try WebSocket.Server.getServerList().randomElement() else {
            throw Fulcrum.Error.transport(.setupFailed)
        }
        return url
    }
}

@Suite("Client – Connection")
struct ClientConnectionTests {
    let client: Client

    init() throws {
        let socket = WebSocket(url: try .randomFulcrum())
        self.client = Client(webSocket: socket)
    }

    @Test("start → stop happy-path")
    func startAndStop() async throws {
        try await client.start()
        #expect(await client.webSocket.isConnected)

        await client.stop()
        #expect(!(await client.webSocket.isConnected))
    }

    @Test("explicit stop reason")
    func stopWithReason() async throws {
        try await client.start()
        #expect(await client.webSocket.isConnected)

        await client.webSocket.disconnect(with: "Unit-test teardown")
        #expect(!(await client.webSocket.isConnected))
    }

    @Test("invalid URL fails")
    func faultyURL() async throws {
        let bogusURL  = URL(string: "wss://totally.invalid.host")!
        let badClient = Client(webSocket: WebSocket(url: bogusURL))

        await #expect(throws: Swift.Error.self) {
            try await badClient.start()
        }
        await badClient.stop()
    }
}

@Suite("Client – Requests")
struct ClientRequestTests {
    let client: Client

    init() throws {
        let socket = WebSocket(url: try .randomFulcrum())
        self.client = Client(webSocket: socket)
    }

    @Test("regular call succeeds (‘blockchain.relayfee’)")
    func relayFeeRequest() async throws {
        try await client.start()
        defer { Task { await client.stop() } }

        let fee: Double = try await client.call(method: .blockchain(.relayFee))
        print("Relay Fee: \(fee.description)")
        #expect(fee > 0)
    }
}

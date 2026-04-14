// NetworkTestClient.swift

import Foundation
import SwiftFulcrum

public struct NetworkTestClient {
    public static func runWithClient(
        _ url: URL,
        _ body: @Sendable (SwiftFulcrum.Client) async throws -> Void
    ) async throws {
        let client = try await SwiftFulcrum.Client(connectingTo: url)

        do {
            try await client.start()
            try await body(client)
            await client.stop()
        } catch {
            await client.stop()
            throw error
        }
    }

    public static func detectStreamTermination<Element: Sendable>(
        _ stream: AsyncThrowingStream<Element, Swift.Error>,
        within timeout: Duration
    ) async -> Bool {
        await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                var iterator = stream.makeAsyncIterator()
                do {
                    while let _ = try await iterator.next() {
                        // Drain until termination.
                    }
                    return true
                } catch {
                    // Treat errors as termination for test purposes.
                    return true
                }
            }

            group.addTask {
                try? await Task.sleep(for: timeout)
                return false
            }

            let result = await group.next() ?? false
            group.cancelAll()
            return result
        }
    }

    public static func pickServerURL(
        network: SwiftFulcrum.Client.Configuration.Network = .mainnet
    ) async throws -> URL {
        try await TestEndpointPolicy.resolveServerURL(network: network)
    }
}

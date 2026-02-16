import Foundation
@testable import SwiftFulcrum

struct NetworkTestClient {
    static func runWithClient(
        _ url: URL,
        _ body: @Sendable (FulcrumClient) async throws -> Void
    ) async throws {
        let client = try await FulcrumClient(url: url.absoluteString)

        do {
            try await client.start()
            try await body(client)
            await client.stop()
        } catch {
            await client.stop()
            throw error
        }
    }

    static func detectStreamTermination<Element: Sendable>(
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

    static func pickRandomServerURL(
        network: FulcrumClient.Configuration.NetworkModel = .mainnet
    ) async throws -> URL {
        let serverList = try await FulcrumServerCatalogRepository.bundled.loadServers(
            for: network,
            fallback: .init()
        )
        guard let selectedURL = serverList.randomElement() else {
            throw FulcrumClient.Error.transport(.setupFailed)
        }
        return selectedURL
    }
}

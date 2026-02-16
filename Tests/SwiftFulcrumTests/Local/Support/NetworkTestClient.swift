import Foundation
@testable import SwiftFulcrum

struct NetworkTestClient {
    static func runWithFulcrum(
        _ url: URL,
        _ body: @Sendable (Fulcrum) async throws -> Void
    ) async throws {
        let fulcrum = try await Fulcrum(url: url.absoluteString)

        do {
            try await fulcrum.start()
            try await body(fulcrum)
            await fulcrum.stop()
        } catch {
            await fulcrum.stop()
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

    static func pickRandomFulcrumURL(
        network: Fulcrum.Configuration.Network = .mainnet
    ) async throws -> URL {
        let serverList = try await FulcrumServerCatalogLoader.bundled.loadServers(
            for: network,
            fallback: .init()
        )
        guard let selectedURL = serverList.randomElement() else {
            throw Fulcrum.Error.transport(.setupFailed)
        }
        return selectedURL
    }
}

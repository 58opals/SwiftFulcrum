import Foundation
@testable import SwiftFulcrum

@discardableResult
func waitUntil(
    timeout: Duration = .seconds(5),
    interval: Duration = .milliseconds(25),
    _ condition: @Sendable () async -> Bool
) async -> Bool {
    let start = ContinuousClock.now
    while await !condition() {
        if ContinuousClock.now - start > timeout { return false }
        try? await Task.sleep(for: interval)
    }
    return true
}

func withRunningFulcrum(
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

func streamTerminates<Element: Sendable>(
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

func randomFulcrumURL(network: Fulcrum.Configuration.Network = .mainnet) async throws -> URL {
    let list = try await WebSocket.Server.fetchServerList(for: network)
    guard let url = list.randomElement() else {
        throw Fulcrum.Error.transport(.setupFailed)
    }
    return url
}

func awaitNextValue<Element: Sendable>(
    in stream: AsyncThrowingStream<Element, Swift.Error>,
    timeout: Duration
) async -> Element? {
    await withTaskGroup(of: Element?.self) { group in
        group.addTask {
            var iterator = stream.makeAsyncIterator()
            return try? await iterator.next()
        }
        
        group.addTask {
            try? await Task.sleep(for: timeout)
            return nil
        }
        
        let result = await group.next() ?? nil
        group.cancelAll()
        return result
    }
}

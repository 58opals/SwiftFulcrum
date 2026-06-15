// ServerCatalogRepositoryValidator~Support.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ServerCatalogRepositoryValidator {
    func loadSanitizedFallbackServers(_ fallbackServers: [URL]) async throws -> [URL] {
        let fallbackLoader = FallbackLoader()
        let loader = SwiftFulcrum.ServerCatalog.Repository { _, fallback in
            try await fallbackLoader.load(fallback)
        }

        return try await loader.loadServers(for: .mainnet, fallback: fallbackServers)
    }

    func expectServerCatalogEntryDecodeFailure(_ json: String, redactedValue: String? = nil) {
        let data = Data(json.utf8)
        let redactedValue = redactedValue ?? (try? JSONRPCCodec.Coder.decoder.decode(String.self, from: data))

        do {
            _ = try JSONRPCCodec.Coder.decoder.decode(WebSocketConnection.Server.self, from: data)
            Issue.record("Expected server catalog entry decode failure")
        } catch let error as DecodingError {
            if let redactedValue {
                #expect(!String(describing: error).contains(redactedValue))
            }
        } catch {
            Issue.record("Unexpected non-DecodingError: \(error)")
        }
    }
}

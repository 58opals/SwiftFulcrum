// ServerCatalogRepositoryValidator~ConstantCatalog.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ServerCatalogRepositoryValidator {
    @Test("Constant catalog filters invalid catalog entries")
    func constantCatalogFiltersInvalidEntries() async throws {
        let validServerOne = URL(string: "wss://valid-one.fulcrum.example")!
        let validServerTwo = URL(string: "ws://valid-two.fulcrum.example")!
        let loader = SwiftFulcrum.ServerCatalog.Repository.makeConstant([
            URL(string: "http://invalid.fulcrum.example")!,
            validServerOne,
            URL(string: "ftp://invalid-two.fulcrum.example")!,
            validServerTwo
        ])

        let servers = try await loader.loadServers(for: .mainnet, fallback: .init())

        #expect(servers == [validServerOne, validServerTwo])
    }

    @Test("Constant catalog throws when all entries are invalid")
    func constantCatalogThrowsWhenAllEntriesAreInvalid() async {
        let loader = SwiftFulcrum.ServerCatalog.Repository.makeConstant([
            URL(string: "http://invalid.fulcrum.example")!,
            URL(string: "ftp://invalid.fulcrum.example")!
        ])

        await #expect(throws: SwiftFulcrum.Client.Error.transport(.setupFailed)) {
            _ = try await loader.loadServers(for: .mainnet, fallback: .init())
        }
    }

    @Test("Throws when both bundled and fallback catalogs are empty")
    func throwWhenCatalogCannotBeBuilt() async {
        let fallbackLoader = FallbackLoader()
        let loader = SwiftFulcrum.ServerCatalog.Repository { _, _ in
            try await fallbackLoader.load(.init())
        }

        await #expect(throws: SwiftFulcrum.Client.Error.transport(.setupFailed)) {
            _ = try await loader.loadServers(for: .mainnet, fallback: .init())
        }
    }
}

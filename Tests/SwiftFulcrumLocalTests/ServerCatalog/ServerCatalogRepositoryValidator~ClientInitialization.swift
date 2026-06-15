// ServerCatalogRepositoryValidator~ClientInitialization.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ServerCatalogRepositoryValidator {
    @Test("Uses constant catalog during SwiftFulcrum.Client initialization after filtering invalid entries")
    func useConstantCatalogLoader() async throws {
        let expectedServer = URL(string: "wss://injected.fulcrum.example")!
        let loader = SwiftFulcrum.ServerCatalog.Repository.makeConstant([
            URL(string: "http://invalid.fulcrum.example")!,
            expectedServer,
            URL(string: "ftp://invalid-two.fulcrum.example")!
        ])
        let configuration = SwiftFulcrum.Client.Configuration(serverCatalogLoader: loader)

        let clientInterface = try await SwiftFulcrum.Client(configuration: configuration)
        let client = await clientInterface.client
        let transport = await client.transport
        let endpoint = await transport.endpoint

        #expect(endpoint == expectedServer)
    }

    @Test("Client initialization rejects endpoints with invalid ports")
    func clientInitializationRejectsEndpointsWithInvalidPorts() async throws {
        let endpoint = try #require(URL(string: "wss://invalid-port.fulcrum.example:0"))

        await #expect(throws: SwiftFulcrum.Client.Error.self) {
            _ = try await SwiftFulcrum.Client(connectingTo: endpoint)
        }
    }

    @Test(
        "Client initialization rejects endpoints with disallowed URL components",
        arguments: [
            "wss://user@invalid.fulcrum.example",
            "wss://invalid.fulcrum.example#fragment"
        ]
    )
    func clientInitializationRejectsEndpointsWithDisallowedURLComponents(_ endpointString: String) async throws {
        let endpoint = try #require(URL(string: endpointString))

        await #expect(throws: SwiftFulcrum.Client.Error.self) {
            _ = try await SwiftFulcrum.Client(connectingTo: endpoint)
        }
    }

    @Test("Client initialization ignores invalid custom catalog entries when a valid endpoint exists")
    func clientInitializationIgnoresInvalidCustomCatalogEntries() async throws {
        let expectedServer = URL(string: "wss://valid.fulcrum.example")!
        let invalidServers = (0 ..< 32).map { index in
            URL(string: "http://invalid-\(index).fulcrum.example")!
        }
        let loader = SwiftFulcrum.ServerCatalog.Repository { _, _ in
            invalidServers + [expectedServer]
        }
        let configuration = SwiftFulcrum.Client.Configuration(serverCatalogLoader: loader)

        for attempt in 0 ..< 8 {
            do {
                let clientInterface = try await SwiftFulcrum.Client(configuration: configuration)
                let client = await clientInterface.client
                let transport = await client.transport
                let endpoint = await transport.endpoint

                #expect(endpoint == expectedServer)
                await clientInterface.stop()
            } catch {
                Issue.record(
                    "Attempt \(attempt) should have selected the valid endpoint instead of failing: \(error)"
                )
                return
            }
        }
    }
}

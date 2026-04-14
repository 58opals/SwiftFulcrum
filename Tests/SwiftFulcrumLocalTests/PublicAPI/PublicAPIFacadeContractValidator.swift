// PublicAPIFacadeContractValidator.swift

import Foundation
import Testing
import SwiftFulcrum

@Suite(.tags(.local))
struct PublicAPIFacadeContractValidator {
    @Test("Facade namespace aliases compile")
    func facadeAliasesCompile() {
        let clientType: SwiftFulcrum.Client.Type = SwiftFulcrum.Client.self
        _ = clientType

        let configurationType: SwiftFulcrum.Client.Configuration.Type = SwiftFulcrum.Client.Configuration.self
        _ = configurationType

        let callOptionsType: SwiftFulcrum.Client.Call.Options.Type = SwiftFulcrum.Client.Call.Options.self
        _ = callOptionsType

        let subscriptionType: SwiftFulcrum.Client.Subscription<
            SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.Subscribe,
            SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.SubscribeNotification
        >.Type = SwiftFulcrum.Client.Subscription.self
        _ = subscriptionType

        let diagnosticsType: SwiftFulcrum.Client.Diagnostics.Type = SwiftFulcrum.Client.Diagnostics.self
        _ = diagnosticsType

        let connectionStateType: SwiftFulcrum.Client.ConnectionState.Type = SwiftFulcrum.Client.ConnectionState.self
        _ = connectionStateType

        let clientErrorType: SwiftFulcrum.Client.Error.Type = SwiftFulcrum.Client.Error.self
        _ = clientErrorType

        let method: SwiftFulcrum.RPC.Method = .blockchain(.headers(.getTip))
        _ = method

        let responseType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.GetTip.Type =
            SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.GetTip.self
        _ = responseType

        let protocolVersionType: SwiftFulcrum.ProtocolVersion.Type = SwiftFulcrum.ProtocolVersion.self
        _ = protocolVersionType

        let transportStateType: SwiftFulcrum.Transport.State.Type = SwiftFulcrum.Transport.State.self
        _ = transportStateType

        let serverCatalogRepositoryType: SwiftFulcrum.ServerCatalog.Repository.Type = SwiftFulcrum.ServerCatalog.Repository.self
        _ = serverCatalogRepositoryType

        _ = SwiftFulcrum.Metrics.MetricsClient.self

        let loggingType: SwiftFulcrum.Logging.Type = SwiftFulcrum.Logging.self
        _ = loggingType

        let unaryRequest: @Sendable (SwiftFulcrum.Client) async throws -> SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.GetTip = { client in
            try await client.request(
                method: .blockchain(.headers(.getTip)),
                responseType: SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.GetTip.self
            )
        }
        _ = unaryRequest

        let streamingRequest: @Sendable (SwiftFulcrum.Client) async throws -> SwiftFulcrum.Client.Subscription<
            SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.Subscribe,
            SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.SubscribeNotification
        > = { client in
            try await client.subscribe(method: .blockchain(.headers(.subscribe)))
        }
        _ = streamingRequest
    }

    @Test(
        "Generated public symbol graph excludes removed wrapper types",
        .enabled(if: Self.hasGeneratedPublicSymbolGraph, "Run `swift package dump-symbol-graph` to enable symbol-graph facade validation.")
    )
    func generatedPublicSymbolGraphExcludesRemovedWrapperTypes() throws {
        let symbolGraph = try loadGeneratedPublicSymbolGraph()
        let publicSymbols = Set(symbolGraph.symbols.map { $0.pathComponents.joined(separator: ".") })

        let requiredSymbols = [
            "SwiftFulcrum.Client",
            "SwiftFulcrum.Client.Configuration",
            "SwiftFulcrum.Client.Call.Options",
            "SwiftFulcrum.Client.Subscription",
            "SwiftFulcrum.Client.Diagnostics",
            "SwiftFulcrum.Client.ConnectionState",
            "SwiftFulcrum.Client.Error",
            "SwiftFulcrum.RPC.Method",
            "SwiftFulcrum.RPC.Response.Result",
            "SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.GetTip",
            "SwiftFulcrum.ProtocolVersion",
            "SwiftFulcrum.Transport.State",
            "SwiftFulcrum.ServerCatalog.Repository",
            "SwiftFulcrum.Metrics",
            "SwiftFulcrum.Logging",
            "SwiftFulcrum.Metrics.MetricsClient",
            "SwiftFulcrum.Logging.Adapter"
        ]

        for symbol in requiredSymbols {
            #expect(publicSymbols.contains(symbol))
        }

        let hiddenSymbols = [
            "SwiftFulcrum.Client.RPCResponse",
            "SwiftFulcrum.Client.RPCSingleResponse",
            "SwiftFulcrum.Client.RPCStreamResponse",
            "SwiftFulcrum.RPC.Response.Regular",
            "SwiftFulcrum.RPC.Response.Subscription",
            "SwiftFulcrum.RPC.Response.Error",
            "SwiftFulcrum.RPC.Response.Kind",
            "SwiftFulcrum.RPC.Response.Identifier",
            "SwiftFulcrum.RPC.JSONRPCResponseAdapter",
            "SwiftFulcrum.RPC.NilAcceptingResponseAdapter",
            "SwiftFulcrum.RPC.Response.JSONRPC",
            "SwiftFulcrum.RPC.Response.JSONRPC.Generic",
            "SwiftFulcrum.RPC.Response.JSONRPC.Result"
        ]

        for symbol in hiddenSymbols {
            #expect(publicSymbols.contains(symbol) == false)
        }
    }
}

private extension PublicAPIFacadeContractValidator {
    static var hasGeneratedPublicSymbolGraph: Bool {
        guard let symbolGraphURL = try? locateGeneratedPublicSymbolGraph(),
              let symbolGraphModificationDate = try? modificationDate(for: symbolGraphURL),
              let latestSourceModificationDate = try? latestPublicSurfaceModificationDate() else {
            return false
        }

        return symbolGraphModificationDate >= latestSourceModificationDate
    }

    func loadGeneratedPublicSymbolGraph() throws -> SymbolGraphModel {
        let symbolGraphURL = try Self.locateGeneratedPublicSymbolGraph()
        let data = try Data(contentsOf: symbolGraphURL)
        return try JSONDecoder().decode(SymbolGraphModel.self, from: data)
    }

    static func locateGeneratedPublicSymbolGraph() throws -> URL {
        let buildDirectory = packageRootURL().appending(path: ".build")
        guard let enumerator = FileManager.default.enumerator(
            at: buildDirectory,
            includingPropertiesForKeys: nil
        ) else {
            throw SupportError.missingGeneratedSymbolGraph(buildDirectory.path())
        }

        for case let fileURL as URL in enumerator {
            if fileURL.lastPathComponent == "SwiftFulcrum.symbols.json" {
                return fileURL
            }
        }

        throw SupportError.missingGeneratedSymbolGraph(buildDirectory.path())
    }

    static func packageRootURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    static func latestPublicSurfaceModificationDate() throws -> Date {
        let packageRoot = packageRootURL()
        let publicSurfaceRoots = [
            packageRoot.appending(path: "Package.swift"),
            packageRoot.appending(path: "Sources")
        ]

        return try publicSurfaceRoots.reduce(.distantPast) { latestDate, rootURL in
            var isDirectory = ObjCBool(false)
            FileManager.default.fileExists(atPath: rootURL.path(), isDirectory: &isDirectory)
            if isDirectory.boolValue {
                return try max(latestDate, latestModificationDate(in: rootURL))
            }
            return try max(latestDate, modificationDate(for: rootURL))
        }
    }

    static func latestModificationDate(in directoryURL: URL) throws -> Date {
        guard let enumerator = FileManager.default.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isRegularFileKey, .contentModificationDateKey]
        ) else {
            return .distantPast
        }

        var latestDate = Date.distantPast
        for case let fileURL as URL in enumerator {
            let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .contentModificationDateKey])
            guard values.isRegularFile == true else { continue }
            latestDate = max(latestDate, values.contentModificationDate ?? .distantPast)
        }

        return latestDate
    }

    static func modificationDate(for fileURL: URL) throws -> Date {
        let values = try fileURL.resourceValues(forKeys: [.contentModificationDateKey])
        return values.contentModificationDate ?? .distantPast
    }

    struct SymbolGraphModel: Decodable {
        let symbols: [SymbolModel]
    }

    struct SymbolModel: Decodable {
        let pathComponents: [String]
    }

    enum SupportError: Swift.Error {
        case missingGeneratedSymbolGraph(String)
    }
}

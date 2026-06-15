// PublicAPIFacadeContractValidator~Support.swift

import Foundation
import OpalDiagnostics
import Testing
import SwiftFulcrum

extension PublicAPIFacadeContractValidator {
    func loadGeneratedPublicSymbolGraph() throws -> SymbolGraphModel {
        let symbolGraphURL = try Self.locateGeneratedPublicSymbolGraph()
        let data = try Data(contentsOf: symbolGraphURL)
        return try JSONDecoder().decode(SymbolGraphModel.self, from: data)
    }

    static func locateGeneratedPublicSymbolGraph() throws -> URL {
        let buildDirectory = makePackageRootURL().appending(path: ".build")
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

    static func makePackageRootURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    static func findLatestPublicSurfaceModificationDate() throws -> Date {
        let packageRoot = makePackageRootURL()
        let publicSurfaceRoots = [
            packageRoot.appending(path: "Package.swift"),
            packageRoot.appending(path: "Sources")
        ]

        return try publicSurfaceRoots.reduce(.distantPast) { latestDate, rootURL in
            var isDirectory = ObjCBool(false)
            FileManager.default.fileExists(atPath: rootURL.path(), isDirectory: &isDirectory)
            if isDirectory.boolValue {
                return try max(latestDate, findLatestModificationDate(in: rootURL))
            }
            return try max(latestDate, readModificationDate(for: rootURL))
        }
    }

    static func findLatestModificationDate(in directoryURL: URL) throws -> Date {
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

    static func readModificationDate(for fileURL: URL) throws -> Date {
        let values = try fileURL.resourceValues(forKeys: [.contentModificationDateKey])
        return values.contentModificationDate ?? .distantPast
    }
}

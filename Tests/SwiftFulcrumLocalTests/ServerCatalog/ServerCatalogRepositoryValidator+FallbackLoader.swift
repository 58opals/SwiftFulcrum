// ServerCatalogRepositoryValidator+FallbackLoader.swift

import Foundation
@testable import SwiftFulcrum

extension ServerCatalogRepositoryValidator {
    actor FallbackLoader {
        func load(_ fallback: [URL]) throws -> [URL] {
            let sanitized = SwiftFulcrum.ServerCatalog.Repository.sanitizeServers(fallback)
            guard !sanitized.isEmpty else {
                throw SwiftFulcrum.Client.Error.transport(.setupFailed)
            }
            return sanitized
        }
    }
}

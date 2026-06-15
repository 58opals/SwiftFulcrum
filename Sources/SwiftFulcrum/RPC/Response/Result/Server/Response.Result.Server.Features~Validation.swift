// Response.Result.Server.Features~Validation.swift

import Foundation

extension SwiftFulcrum.Response.Server.Features {
    static func validateNonNegative(_ value: Int?, field: String) throws {
        guard let value else { return }
        guard value >= 0 else {
            throw ResponseResultDecodeError.unexpectedFormat("Invalid server.features \(field) value")
        }
    }

    static func validatePort(_ value: Int?, field: String) throws {
        guard let value else { return }
        guard (1 ... 65_535).contains(value) else {
            throw ResponseResultDecodeError.unexpectedFormat("Invalid server.features \(field) value")
        }
    }
}

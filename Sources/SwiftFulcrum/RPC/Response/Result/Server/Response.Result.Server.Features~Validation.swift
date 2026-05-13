// Response.Result.Server.Features~Validation.swift

import Foundation

extension SwiftFulcrum.Response.Server.Features {
    static func validate(_ value: Int?, field: String, range: ClosedRange<Int>) throws {
        guard let value else { return }
        guard range.contains(value) else {
            throw ResponseResultDecodeError.unexpectedFormat("Invalid server.features \(field): \(value)")
        }
    }
}

import Foundation
import Testing
@testable import SwiftFulcrum

@Suite(.tags(.local))
struct ClientErrorEquatableValidator {
    private struct SameMessageOne: LocalizedError {
        var errorDescription: String? { "shared failure" }
    }

    private struct SameMessageTwo: LocalizedError {
        var errorDescription: String? { "shared failure" }
    }

    @Test("Unknown wrapped errors compare by identity, not localized text")
    func compareUnknownWrappedErrorsByIdentity() {
        let left = SwiftFulcrum.Client.Error.client(.unknown(SameMessageOne()))
        let right = SwiftFulcrum.Client.Error.client(.unknown(SameMessageTwo()))

        #expect(left != right)
    }

    @Test("Coding wrapped errors compare by identity, not localized text")
    func compareCodingWrappedErrorsByIdentity() {
        let left = SwiftFulcrum.Client.Error.coding(.encode(SameMessageOne()))
        let right = SwiftFulcrum.Client.Error.coding(.encode(SameMessageTwo()))

        #expect(left != right)
    }

    @Test("Network wrapped errors compare by identity, not localized text")
    func compareNetworkWrappedErrorsByIdentity() {
        let left = SwiftFulcrum.Client.Error.transport(.network(.tlsNegotiationFailed(SameMessageOne())))
        let right = SwiftFulcrum.Client.Error.transport(.network(.tlsNegotiationFailed(SameMessageTwo())))

        #expect(left != right)
    }

    @Test("Wrapped errors with matching identity remain equal")
    func compareMatchingWrappedErrors() {
        let left = SwiftFulcrum.Client.Error.client(.unknown(URLError(.timedOut)))
        let right = SwiftFulcrum.Client.Error.client(.unknown(URLError(.timedOut)))

        #expect(left == right)
    }
}

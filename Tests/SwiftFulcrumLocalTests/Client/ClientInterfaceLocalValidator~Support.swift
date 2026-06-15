// ClientInterfaceLocalValidator~Support.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension ClientInterfaceLocalValidator {
    func completeProtocolNegotiation(on transport: TransportTestActor) async throws {
        let versionRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let versionIdentifier = try extractRequestIdentifier(from: versionRequest)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresRequest = try await decodeRequestObject(await transport.dequeueOutgoing())
        let featuresIdentifier = try extractRequestIdentifier(from: featuresRequest)
        let featuresPayload = try TransportTestActor.encodeResponsePayload(
            identifier: featuresIdentifier,
            result: [
                "genesis_hash": String(repeating: "0", count: 64),
                "hash_function": "sha256",
                "server_version": "SwiftFulcrum.Client 2.0",
                "protocol_max": "1.6.0",
                "protocol_min": "1.4.0"
            ]
        )
        await transport.enqueueIncoming(.data(featuresPayload))
    }

    func decodeRequestObject(_ message: URLSessionWebSocketTask.Message) async throws -> [String: Any] {
        try TransportTestActor.decodeJSONObject(from: message)
    }

    func extractRequestIdentifier(from object: [String: Any]) throws -> String {
        guard let identifier = object["id"] as? String else {
            throw SupportError.missingRequestIdentifier
        }

        return identifier
    }
}

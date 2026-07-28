// FulcrumClientLifecycleValidator~ProtocolNegotiationSupport.swift

import Foundation
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    func makeActiveHeadersSubscription(
        on fulcrum: SwiftFulcrum.Client,
        transport: TransportTestActor,
        height: Int = 930_000
    ) async throws -> HeadersSubscription {
        let method = SwiftFulcrum.RPC.Method.blockchain(.headers(.subscribe))
        let subscribeTask = Task<HeadersSubscription, Swift.Error> {
            try await fulcrum.subscribe(
                method: method,
                options: .init(timeout: .seconds(30))
            )
        }

        let request = try await decodeRequestObject(await transport.dequeueOutgoing())
        let identifier = try extractRequestIdentifier(from: request)
        let payload = try TransportTestActor.encodeResponsePayload(
            identifier: identifier,
            result: [
                "height": height,
                "hex": String(repeating: "a", count: 160)
            ]
        )
        await transport.enqueueIncoming(.data(payload))
        return try await subscribeTask.value
    }

    func completeProtocolNegotiation(on transport: TransportTestActor) async throws {
        let versionObject = try await decodeRequestObject(await transport.dequeueOutgoing())
        let versionIdentifier = try extractRequestIdentifier(from: versionObject)
        let versionPayload = try TransportTestActor.encodeResponsePayload(
            identifier: versionIdentifier,
            result: ["SwiftFulcrum.Client 2.0", "1.5.3"]
        )
        await transport.enqueueIncoming(.data(versionPayload))

        let featuresObject = try await decodeRequestObject(await transport.dequeueOutgoing())
        let featuresIdentifier = try extractRequestIdentifier(from: featuresObject)
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
}

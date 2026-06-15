// FulcrumClientLifecycleValidator~ReconnectSupport.swift

import Foundation
import Testing
import SwiftFulcrumTestSupport
@testable import SwiftFulcrum

extension FulcrumClientLifecycleValidator {
    func dequeueNextRequestObject(
        matching methodPath: String,
        transport: TransportTestActor
    ) async throws -> [String: Any] {
        while true {
            let request = try await decodeRequestObject(await transport.dequeueOutgoing())
            let queuedMethodPath = try #require(request["method"] as? String)

            switch queuedMethodPath {
            case methodPath:
                return request
            case SwiftFulcrum.RPC.Method.server(.ping).path:
                let pingIdentifier = try extractRequestIdentifier(from: request)
                let pingPayload = try TransportTestActor.encodeResponsePayload(
                    identifier: pingIdentifier,
                    result: NSNull()
                )
                await transport.enqueueIncoming(.data(pingPayload))
            default:
                Issue.record("Unexpected request during reconnect recovery: \(queuedMethodPath)")
            }
        }
    }
}

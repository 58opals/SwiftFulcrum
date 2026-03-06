// FulcrumNetworkClient~SendFulcrumRequest.swift

import Foundation

extension FulcrumNetworkClient {
    func send(request: FulcrumRequest) async throws {
        try Task.checkCancellation()

        if case .server(.version) = request.requestedMethod {
            guard let data = request.data else { throw SwiftFulcrum.Client.Error.coding(.encode(nil)) }
            try Task.checkCancellation()
            try await self.send(data: data)
            return
        }

        _ = try await ensureNegotiatedProtocol()

        guard let data = request.data else { throw SwiftFulcrum.Client.Error.coding(.encode(nil)) }
        try Task.checkCancellation()
        try await self.send(data: data)
    }

    func cancelUnary(_ id: UUID, error: Swift.Error? = nil) async {
        let inflight = await router.cancel(identifier: .uuid(id), error: error)
        await publishDiagnosticsSnapshot(inflightUnaryCallCount: inflight)
    }
}

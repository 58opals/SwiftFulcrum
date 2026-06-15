// FulcrumNetworkClient~WebSocketConnection.swift

import Foundation
import OpalDiagnostics

extension FulcrumNetworkClient {
    func send(data: Data) async throws {
        try await transport.send(data: data)
    }

    func send(string: String) async throws {
        try await transport.send(string: string)
    }
}

extension FulcrumNetworkClient {
    func startReceiving() async {
        defer { receiveTask = nil }

        do {
            for try await message in await transport.makeMessageStream() {
                if let inflightCount = await handleMessage(message) { await recordClientState(inflightUnaryCallCount: inflightCount) }
            }
        } catch {
            OpalDiagnostics.logger(category: .swiftFulcrumWebSocket).record(
                event: .swiftFulcrumWebSocketReceiveFailed,
                level: .info,
                fields: makeClientDiagnosticFields(OpalDiagnostics.Field.swiftFulcrumErrorFields(error))
            )

            let info = await transport.closeInformation
            let closedError = await SwiftFulcrum.Client.Error.transport(.connectionClosed(info.code, info.reason))

            let inflightCount = await self.router.failUnaries(with: closedError)
            await recordClientState(inflightUnaryCallCount: inflightCount)
        }
    }
}

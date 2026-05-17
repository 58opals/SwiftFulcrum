// FulcrumNetworkClient~Heartbeat.swift

import Foundation
import OpalDiagnostics

extension FulcrumNetworkClient {
    func startRPCHeartbeat() {
        rpcHeartbeatTask?.cancel()
        let owner = self
        rpcHeartbeatTask = Task {
            
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: owner.rpcHeartbeatInterval)
                    try Task.checkCancellation()
                    
                    let (_, _): (UUID, SwiftFulcrum.Response.Server.Ping) =
                    try await owner.call(
                        method: .server(.ping),
                        options: .init(timeout: owner.rpcHeartbeatTimeout)
                    )
                } catch is CancellationError {
                    // Expected during stop(); do not treat as timeout.
                    break
                } catch {
                    // If we were cancelled while handling an error, bail out.
                    if Task.isCancelled { break }
                    
                    OpalDiagnostics.logger(category: .fulcrum).record(
                        event: .swiftFulcrumClientHeartbeatTimeout,
                        level: .info,
                        fields: await owner.makeClientTransportDiagnosticFields(OpalDiagnostics.Field.swiftFulcrumErrorFields(error))
                    )
                    
                    do {
                        try Task.checkCancellation()
                        try await owner.reconnect()
                    } catch is CancellationError {
                        break
                    } catch {
                        let heartbeatTimeoutError = SwiftFulcrum.Client.Error.transport(.heartbeatTimeout)
                        let inflightCount = await owner.router.failAll(with: heartbeatTimeoutError)
                        await owner.dropAllStoredSubscriptions()
                        await owner.recordClientState(inflightUnaryCallCount: inflightCount)
                        break
                    }
                }
            }
        }
    }
    
    func stopRPCHeartbeat() async {
        rpcHeartbeatTask?.cancel()
        await rpcHeartbeatTask?.value
        rpcHeartbeatTask = nil
    }
}

// FulcrumNetworkClient~Heartbeat.swift

import Foundation

extension FulcrumNetworkClient {
    func startRPCHeartbeat() {
        rpcHeartbeatTask?.cancel()
        let owner = self
        rpcHeartbeatTask = Task {
            
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: owner.rpcHeartbeatInterval)
                    try Task.checkCancellation()
                    
                    let (_, _): (UUID, SwiftFulcrum.RPC.Response.Result.Server.Ping) =
                    try await SwiftFulcrum.Logging.perform(withBehavior: .quiet) {
                        try await owner.call(
                            method: .server(.ping),
                            options: .init(timeout: owner.rpcHeartbeatTimeout),
                            suppressTransportLogging: true
                        )
                    }
                } catch is CancellationError {
                    // Expected during stop(); do not treat as timeout.
                    break
                } catch {
                    // If we were cancelled while handling an error, bail out.
                    if Task.isCancelled { break }
                    
                    await owner.emitLog(.warning, "client.heartbeat.rpc_timeout",
                                       metadata: ["error": error.localizedDescription])
                    
                    do {
                        try Task.checkCancellation()
                        try await owner.reconnect()
                    } catch is CancellationError {
                        break
                    } catch {
                        let heartbeatTimeoutError = SwiftFulcrum.Client.Error.transport(.heartbeatTimeout)
                        let inflightCount = await owner.router.failAll(with: heartbeatTimeoutError)
                        await owner.dropAllStoredSubscriptions()
                        await owner.publishDiagnosticsSnapshot(inflightUnaryCallCount: inflightCount)
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

// Client~Heartbeat.swift

import Foundation

extension Client {
    func startRPCHeartbeat() {
        rpcHeartbeatTask?.cancel()
        rpcHeartbeatTask = Task { [weak self] in
            guard let self else { return }
            
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: rpcHeartbeatInterval)
                    try Task.checkCancellation()
                    
                    let (_, _): (UUID, Response.Result.Server.Ping) =
                    try await self.call(
                        method: .server(.ping),
                        options: .init(timeout: rpcHeartbeatTimeout)
                    )
                } catch is CancellationError {
                    // Expected during stop(); do not treat as timeout.
                    break
                } catch {
                    // If we were cancelled while handling an error, bail out.
                    if Task.isCancelled { break }
                    
                    await self.emitLog(.warning, "client.heartbeat.rpc_timeout",
                                       metadata: ["error": error.localizedDescription])
                    
                    do {
                        try Task.checkCancellation()
                        try await self.reconnect()
                    } catch is CancellationError {
                        break
                    } catch {
                        let inflightCount = await self.router.failUnaries(with: Fulcrum.Error.transport(.heartbeatTimeout))
                        await self.publishDiagnosticsSnapshot(inflightUnaryCallCount: inflightCount)
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

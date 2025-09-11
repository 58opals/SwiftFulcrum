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
                    if Task.isCancelled { break }
                    
                    let (_, _): (UUID, Response.Result.Blockchain.Headers.GetTip) = try await self.call(method: .blockchain(.headers(.getTip)), options: .init(timeout: rpcHeartbeatTimeout))
                } catch {
                    await self.emitLog(.warning, "client.heartbeat.rpc_timeout",
                                       metadata: ["error" : error.localizedDescription])
                    do {
                        try await self.reconnect()
                        await self.resubscribeStoredMethods()
                    } catch {
                        await self.router.failUnaries(with: Fulcrum.Error.transport(.heartbeatTimeout))
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

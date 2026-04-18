// WebSocketModel~Connection.swift

import Foundation

extension WebSocketModel {
    func connect(
        shouldEmitLifecycle: Bool = true,
        shouldAllowFailover: Bool = true,
        shouldCancelReceiver: Bool = true
    ) async throws {
        guard await !self.isConnected else { return }
        await updateConnectionState(.connecting)
        
        await createNewTask(with: nil, shouldCancelReceiver: shouldCancelReceiver)
        guard let task else {
            throw SwiftFulcrum.Client.Error.transport(.connectionClosed(closeInformation.code, closeInformation.reason))
        }
        
        task.resume()
        emitLog(.info, "connect.begin")
        
        do {
            let isConnected = try await waitForConnection(timeout: connectionTimeout)
            if isConnected {
                await updateConnectionState(.connected)
                emitLog(.info, "connect.succeeded")
                await metrics?.recordConnect(url: url, network: network)
                if shouldEmitLifecycle { emitLifecycle(.connected(isReconnect: false)) }
                ensureAutomaticReceiving()
            } else {
                await updateConnectionState(.disconnected)
                task.cancel(with: .goingAway, reason: "Connection timed out.".data(using: .utf8))
                emitLog(.error, "connect.timeout")
                try await performInitialFailoverIfNeeded(
                    shouldAllowFailover: shouldAllowFailover,
                    failure: SwiftFulcrum.Client.Error.transport(
                        .connectionClosed(closeInformation.code, closeInformation.reason)
                    )
                )
            }
        } catch let networkError as SwiftFulcrum.Client.Error.Network {
            await updateConnectionState(.disconnected)
            task.cancel(with: .goingAway, reason: "Network error during connect.".data(using: .utf8))
            try await performInitialFailoverIfNeeded(
                shouldAllowFailover: shouldAllowFailover,
                failure: SwiftFulcrum.Client.Error.transport(.network(networkError))
            )
        } catch {
            await updateConnectionState(.disconnected)
            task.cancel(with: .goingAway, reason: "Connect failed.".data(using: .utf8))
            try await performInitialFailoverIfNeeded(
                shouldAllowFailover: shouldAllowFailover,
                failure: error
            )
        }
    }
    
    private func performInitialFailoverIfNeeded(
        shouldAllowFailover: Bool,
        failure: Error
    ) async throws {
        guard shouldAllowFailover else { throw failure }
        
        emitLog(
            .warning,
            "connect.failover",
            metadata: ["error": failure.localizedDescription]
        )
        
        do {
            await updateConnectionState(.reconnecting)
            try await reconnector.attemptReconnection(
                for: self,
                shouldCancelReceiver: true,
                isInitialConnection: true
            )
        } catch {
            emitLog(
                .error,
                "connect.failover_exhausted",
                metadata: ["error": error.localizedDescription]
            )
            
            throw error
        }
    }
    
    func reconnect(with url: URL? = nil) async throws {
        await disconnect(with: "WebSocketModel.reconnect()")
        await updateConnectionState(.reconnecting)
        do {
            try await reconnector.attemptReconnection(for: self, with: url, shouldCancelReceiver: false)
        } catch {
            await updateConnectionState(.disconnected)
            throw error
        }
    }
    
    func disconnect(with reason: String? = nil) async {
        await cancelReceiverTask()
        
        let existingInformation = closeInformation
        if let task {
            await connectionEventTracker?.stopTracking(taskIdentifier: task.taskIdentifier)
        }
        
        task?.cancel(with: .goingAway, reason: reason?.data(using: .utf8))
        task = nil

        let finalInformation: (code: URLSessionWebSocketTask.CloseCode, reason: String?)
        if let reason {
            finalInformation = (.goingAway, reason)
        } else {
            finalInformation = existingInformation
        }

        await updateConnectionState(.disconnected)

        let closedError = SwiftFulcrum.Client.Error.transport(
            .connectionClosed(finalInformation.code, finalInformation.reason)
        )
        
        finishConnectWaiters(.failure(closedError))
        
        messageContinuation?.finish(throwing: closedError)
        
        await metrics?.recordDisconnect(
            url: url,
            closeCode: finalInformation.code,
            reason: finalInformation.reason
        )
        await resetMessageStreamAndReader()
        emitLog(.info, "disconnect", metadata: [
            "reason": finalInformation.reason ?? "nil",
            "code": String(finalInformation.code.rawValue)
        ])
        emitLifecycle(.disconnected(code: finalInformation.code, reason: finalInformation.reason))
    }
}

// WebSocketModel~ConnectionWait.swift

import Foundation

extension WebSocketModel {
    func finishConnectWaiters(_ result: Result<Bool, Error>) {
        let waiters = connectWaiters
        connectWaiters.removeAll(keepingCapacity: false)
        isConnectionInFlight = false
        for continuation in waiters {
            switch result {
            case .success(let isSuccessful): continuation.resume(returning: isSuccessful)
            case .failure(let error): continuation.resume(throwing: error)
            }
        }
    }
    
    func waitForConnection(timeout: TimeInterval) async throws -> Bool {
        if await isConnected { return true }
        
        if isConnectionInFlight {
            return try await withCheckedThrowingContinuation { continuation in
                connectWaiters.append(continuation)
            }
        }
        
        isConnectionInFlight = true
        do {
            let isSuccessful = try await waitForConnectionOnce(timeout: timeout)
            finishConnectWaiters(.success(isSuccessful))
            return isSuccessful
        } catch {
            finishConnectWaiters(.failure(error))
            throw error
        }
    }
    
    private func waitForConnectionOnce(timeout: TimeInterval) async throws -> Bool {
        guard let task else {
            throw SwiftFulcrum.Client.Error.transport(.connectionClosed(closeInformation.code, closeInformation.reason))
        }
        
        let (stream, continuation) = AsyncThrowingStream<Bool, Error>.makeStream()
        let currentURL = self.url
        let metrics = self.metrics
        
        task.sendPing { error in
            if let metrics { Task { await metrics.recordPing(url: currentURL, error: error) } }
            if let error {
                continuation.finish(throwing: SwiftFulcrum.Client.Error.NetworkModel.tlsNegotiationFailed(error))
            } else {
                _ = continuation.yield(true); continuation.finish()
            }
        }
        
        return try await withThrowingTaskGroup(of: Bool.self) { group in
            group.addTask {
                var iterator = stream.makeAsyncIterator()
                guard let isSuccessful = try await iterator.next() else {
                    return false
                }
                return isSuccessful
            }
            
            group.addTask {
                try await Task.sleep(for: .seconds(timeout))
                return false
            }
            
            let winner = try await group.next() ?? false
            group.cancelAll()
            return winner
        }
    }
}

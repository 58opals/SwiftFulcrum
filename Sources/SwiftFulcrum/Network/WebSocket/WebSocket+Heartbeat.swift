// WebSocket+Heartbeat.swift

import Foundation

extension WebSocket {
    public enum Heartbeat {}
}

extension WebSocket.Heartbeat {
    public struct Configuration: Sendable {
        public let interval: TimeInterval
        public let missTolerance: Int
        
        public init(interval: TimeInterval, missTolerance: Int) {
            self.interval = interval
            self.missTolerance = missTolerance
        }
    }
}

extension WebSocket {
    func startHeartbeatIfNeeded() {
        guard heartbeatTask == nil, let configuration = heartbeatConfiguration else { return }
        let capturedConfiguration = configuration
        self.heartbeatTask = Task { [capturedConfiguration] in
            await self.runHeartbeat(capturedConfiguration)
        }
    }
    
    func stopHeartbeat() async {
        heartbeatTask?.cancel()
        await heartbeatTask?.value
        heartbeatTask = nil
    }
    
    private func runHeartbeat(_ configuration: Heartbeat.Configuration) async {
        var missed = 0
        while !Task.isCancelled {
            do {
                try await Task.sleep(for: .seconds(configuration.interval))
                try await ping(within: configuration.interval)
                missed = 0
            } catch {
                missed += 1
                if missed > configuration.missTolerance {
                    do {
                        try await reconnector.attemptReconnection(for: self)
                        missed = 0
                    } catch {
                        messageContinuation?.finish(throwing: error)
                        break
                    }
                }
            }
        }
    }
    
    private func ping(within timeout: TimeInterval) async throws {
        guard let task else {
            throw Fulcrum.Error.transport(.connectionClosed(closeInformation.code, closeInformation.reason))
        }
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await withCheckedThrowingContinuation { continuation in
                    task.sendPing { error in
                        if let error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    }
                }
            }
            
            group.addTask {
                try await Task.sleep(for: .seconds(timeout))
                throw Fulcrum.Error.transport(.heartbeatTimeout)
            }
            
            _ = try await group.next()
            group.cancelAll()
        }
    }
}

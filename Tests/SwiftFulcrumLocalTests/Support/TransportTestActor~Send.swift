// TransportTestActor~Send.swift

import Foundation
@testable import SwiftFulcrum

extension TransportTestActor {
    func send(data: Data, sendAuthorization: SwiftFulcrum.Client.Call.SendAuthorization?) async throws {
        try await applyOutgoingSendDelayIfNeeded()
        try await applyOutgoingSendPauseIfNeeded()
        if let error = consumeOutgoingSendFailure(from: data) {
            throw error
        }
        try Task.checkCancellation()
        try sendAuthorization?.validate()
        recordOutgoing(.data(data))
        await pauseSendCompletionIfNeeded(data)
    }

    func send(string: String, sendAuthorization: SwiftFulcrum.Client.Call.SendAuthorization?) async throws {
        try await applyOutgoingSendDelayIfNeeded()
        try await applyOutgoingSendPauseIfNeeded()
        if let data = string.data(using: .utf8), let error = consumeOutgoingSendFailure(from: data) {
            throw error
        }
        try Task.checkCancellation()
        try sendAuthorization?.validate()
        recordOutgoing(.string(string))
        if let data = string.data(using: .utf8) { await pauseSendCompletionIfNeeded(data) }
    }

    func pauseSendCompletionIfNeeded(_ data: Data) async {
        guard let method = pausedSendCompletionMethod,
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              object["method"] as? String == method else { return }
        pausedSendCompletionMethod = nil
        await withCheckedContinuation { pausedSendCompletionContinuations.append($0) }
    }

    func resumeSendCompletion() {
        let pending = pausedSendCompletionContinuations
        pausedSendCompletionContinuations.removeAll()
        for continuation in pending { continuation.resume() }
    }

    func pauseNextSendCompletion(method: String) { pausedSendCompletionMethod = method }

    func recordOutgoing(_ message: URLSessionWebSocketTask.Message) {
        sentMessages.append(message)
        outgoingQueue.append(message)
        resolvePendingOutgoingContinuations()
    }

    func consumeOutgoingSendFailure(from data: Data) -> Swift.Error? {
        guard
            let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let methodPath = jsonObject["method"] as? String
        else {
            return nil
        }

        return outgoingSendFailuresByMethodPath.removeValue(forKey: methodPath)
    }

    func applyOutgoingSendDelayIfNeeded() async throws {
        guard let outgoingSendDelay else { return }
        try await Task.sleep(for: outgoingSendDelay)
    }

    func applyOutgoingSendPauseIfNeeded() async throws {
        guard shouldPauseOutgoingSend else { return }

        await withCheckedContinuation { continuation in
            pendingOutgoingSendGateContinuations.append(continuation)
        }
        try Task.checkCancellation()
    }

    func applyConnectDelayIfNeeded() async throws {
        guard let connectDelay else { return }
        try await Task.sleep(for: connectDelay)
    }

    func resumePendingOutgoingSends() {
        let continuations = pendingOutgoingSendGateContinuations
        pendingOutgoingSendGateContinuations.removeAll(keepingCapacity: false)

        for continuation in continuations {
            continuation.resume()
        }
    }

    func resolvePendingOutgoingContinuations() {
        while !pendingOutgoingContinuations.isEmpty, !outgoingQueue.isEmpty {
            let continuation = pendingOutgoingContinuations.removeFirst()
            let message = outgoingQueue.removeFirst()
            continuation.resume(returning: message)
        }
    }
}

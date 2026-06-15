// TransportTestActor~Send.swift

import Foundation
@testable import SwiftFulcrum

extension TransportTestActor {
    func send(data: Data) async throws {
        try await applyOutgoingSendDelayIfNeeded()
        try await applyOutgoingSendPauseIfNeeded()
        if let error = consumeOutgoingSendFailure(from: data) {
            throw error
        }
        recordOutgoing(.data(data))
    }

    func send(string: String) async throws {
        try await applyOutgoingSendDelayIfNeeded()
        try await applyOutgoingSendPauseIfNeeded()
        if let data = string.data(using: .utf8), let error = consumeOutgoingSendFailure(from: data) {
            throw error
        }
        recordOutgoing(.string(string))
    }

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

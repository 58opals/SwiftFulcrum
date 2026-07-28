// WebSocketConnection~Disconnection.swift

import Foundation
import OpalDiagnostics

extension WebSocketConnection {
    func disconnect(
        with reason: String? = nil,
        cancellingConnectTask: Bool = true,
        receiverCancellation: ReceiverCancellation = .cancel
    ) async {
        let suppressesReaderStart: Bool
        switch receiverCancellation {
        case .cancel:
            suppressesReaderStart = true
            readerStartSuppressionCount += 1
        case .preserve:
            suppressesReaderStart = false
        }
        defer {
            if suppressesReaderStart {
                readerStartSuppressionCount -= 1
            }
        }

        if cancellingConnectTask {
            connectTask?.cancel()
        }
        switch receiverCancellation {
        case .cancel:
            await cancelReceiverTask()
        case .preserve:
            break
        }

        let existingInformation = closeInformation
        if let task {
            await connectionEventTracker.stopTracking(taskIdentifier: task.taskIdentifier)
        }

        task?.cancel(with: .goingAway, reason: reason?.data(using: .utf8))
        task = nil

        let finalInformation: (code: URLSessionWebSocketTask.CloseCode, reason: String?)
        if let reason {
            finalInformation = (.goingAway, reason)
        } else {
            finalInformation = existingInformation
        }
        lastCloseInformation = finalInformation

        await updateConnectionState(.disconnected)

        let closedError = SwiftFulcrum.Client.Error.transport(
            .connectionClosed(finalInformation.code, finalInformation.reason)
        )

        switch receiverCancellation {
        case .cancel:
            messageContinuation?.finish(throwing: closedError)
            sharedMessagesStream = nil
            messageContinuation = nil
            messageStreamGenerationIdentifier = nil
        case .preserve:
            break
        }
        OpalDiagnostics.logger(category: .swiftFulcrumWebSocket).record(
            event: .swiftFulcrumWebSocketDisconnect,
            level: .info,
            fields: webSocketDiagnosticFields([
                .swiftFulcrumField("close_code", finalInformation.code.rawValue),
                .swiftFulcrumPrivateField("reason", finalInformation.reason ?? "")
            ])
        )
        emitLifecycle(.disconnected(code: finalInformation.code, reason: finalInformation.reason))
    }

    @discardableResult
    func discardCancelledConnectionTask(
        _ cancelledTask: URLSessionWebSocketTask
    ) async -> Bool {
        await connectionEventTracker.stopTracking(taskIdentifier: cancelledTask.taskIdentifier)
        cancelledTask.cancel(with: .goingAway, reason: nil)
        guard task?.taskIdentifier == cancelledTask.taskIdentifier else { return false }
        task = nil
        return true
    }
}

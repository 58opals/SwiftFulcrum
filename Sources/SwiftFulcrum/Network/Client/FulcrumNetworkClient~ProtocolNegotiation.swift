// FulcrumNetworkClient~ProtocolNegotiation.swift

import Foundation

extension FulcrumNetworkClient {
    func ensureNegotiatedProtocol() async throws -> NegotiatedSession {
        if state.negotiatedSession.negotiatedProtocol != nil {
            return state.negotiatedSession
        }

        let generationIdentifier = state.negotiatedSession.generationIdentifier
        let negotiationTask: Task<NegotiatedSession, Swift.Error>
        if let existingNegotiationTask = state.negotiatedSession.negotiationTask {
            negotiationTask = existingNegotiationTask
        } else {
            negotiationTask = Task {
                try await self.performProtocolNegotiation(
                    generationIdentifier: generationIdentifier
                )
            }
            state.negotiatedSession.negotiationTask = negotiationTask
        }

        let cancellationCoordinator = state.negotiatedSession.negotiationCancellationCoordinator
        state.negotiatedSession.negotiationWaiterCount += 1
        cancellationCoordinator.addWaiter()
        defer {
            let remainingWaiterCount = cancellationCoordinator.removeWaiter()
            if state.negotiatedSession.generationIdentifier == generationIdentifier {
                state.negotiatedSession.negotiationWaiterCount -= 1
                if Task.isCancelled, remainingWaiterCount == 0 {
                    negotiationTask.cancel()
                    clearNegotiatedSession(generationIdentifier: generationIdentifier)
                }
            }
        }

        do {
            let negotiatedSession = try await negotiationTask.awaitCancellableValue(
                shouldCancelUnderlyingTask: {
                    cancellationCoordinator.shouldCancelUnderlyingTaskForCancellingWaiter
                }
            )
            guard state.negotiatedSession.generationIdentifier == generationIdentifier else {
                throw CancellationError()
            }
            state.negotiatedSession.negotiatedProtocol = negotiatedSession.negotiatedProtocol
            state.negotiatedSession.serverSoftwareVersion = negotiatedSession.serverSoftwareVersion
            state.negotiatedSession.serverFeatures = negotiatedSession.serverFeatures
            state.negotiatedSession.negotiationTask = nil
            return state.negotiatedSession
        } catch {
            if Task.isCancelled, error is CancellationError {
                throw error
            }
            clearNegotiatedSession(generationIdentifier: generationIdentifier)
            throw error
        }
    }

    private func clearNegotiatedSession(generationIdentifier: UUID) {
        guard state.negotiatedSession.generationIdentifier == generationIdentifier else {
            return
        }
        state.negotiatedSession = .init()
    }

    private func performProtocolNegotiation(
        generationIdentifier: UUID
    ) async throws -> NegotiatedSession {
        let negotiationArgument = protocolNegotiation.makeArgument()
        let supportedRange = protocolNegotiation.supportedRange

        let (_, version): (UUID, SwiftFulcrum.Response.Server.Version) = try await call(
            method: .server(
                .version(
                    clientName: protocolNegotiation.clientName,
                    protocolNegotiation: negotiationArgument
                )
            )
        )

        let negotiatedProtocol = try supportedRange.validateNegotiatedVersion(
            version.negotiatedProtocolVersion
        )

        guard state.negotiatedSession.generationIdentifier == generationIdentifier else {
            throw CancellationError()
        }

        var negotiatedSession = NegotiatedSession(
            generationIdentifier: generationIdentifier
        )
        negotiatedSession.negotiatedProtocol = negotiatedProtocol
        negotiatedSession.serverSoftwareVersion = version.serverVersion
        state.negotiatedSession.negotiatedProtocol = negotiatedSession.negotiatedProtocol
        state.negotiatedSession.serverSoftwareVersion = negotiatedSession.serverSoftwareVersion

        do {
            try Task.checkCancellation()
            let features = try await fetchServerFeatures()
            guard state.negotiatedSession.generationIdentifier == generationIdentifier else {
                throw CancellationError()
            }
            negotiatedSession.serverFeatures = features
            state.negotiatedSession.serverFeatures = features
        } catch {
            guard state.negotiatedSession.generationIdentifier == generationIdentifier else {
                throw CancellationError()
            }
        }

        guard state.negotiatedSession.generationIdentifier == generationIdentifier else {
            throw CancellationError()
        }
        return negotiatedSession
    }

    private func fetchServerFeatures() async throws -> ServerFeatures {
        let (_, features): (UUID, ServerFeatures) = try await call(method: .server(.features))
        return features
    }
}

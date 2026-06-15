// FulcrumNetworkClient~ProtocolNegotiation.swift

import Foundation

extension FulcrumNetworkClient {
    func ensureNegotiatedProtocol() async throws -> NegotiatedSession {
        if state.negotiatedSession.negotiatedProtocol != nil {
            return state.negotiatedSession
        }

        let negotiationTask: Task<NegotiatedSession, Swift.Error>
        if let existingNegotiationTask = state.negotiatedSession.negotiationTask {
            negotiationTask = existingNegotiationTask
        } else {
            negotiationTask = Task { try await self.performProtocolNegotiation() }
            state.negotiatedSession.negotiationTask = negotiationTask
        }

        let cancellationCoordinator = state.negotiatedSession.negotiationCancellationCoordinator
        state.negotiatedSession.negotiationWaiterCount += 1
        cancellationCoordinator.addWaiter()
        defer {
            let remainingWaiterCount = cancellationCoordinator.removeWaiter()
            state.negotiatedSession.negotiationWaiterCount -= 1
            if Task.isCancelled, remainingWaiterCount == 0 {
                negotiationTask.cancel()
                clearNegotiatedSession()
            }
        }

        do {
            let negotiatedSession = try await negotiationTask.awaitCancellableValue(
                shouldCancelUnderlyingTask: {
                    cancellationCoordinator.shouldCancelUnderlyingTaskForCancellingWaiter
                }
            )
            state.negotiatedSession.negotiatedProtocol = negotiatedSession.negotiatedProtocol
            state.negotiatedSession.serverSoftwareVersion = negotiatedSession.serverSoftwareVersion
            state.negotiatedSession.serverFeatures = negotiatedSession.serverFeatures
            state.negotiatedSession.negotiationTask = nil
            return negotiatedSession
        } catch {
            if Task.isCancelled, error is CancellationError {
                throw error
            }
            clearNegotiatedSession()
            throw error
        }
    }

    private func clearNegotiatedSession() {
        state.negotiatedSession.negotiatedProtocol = nil
        state.negotiatedSession.serverSoftwareVersion = nil
        state.negotiatedSession.serverFeatures = nil
        state.negotiatedSession.negotiationTask = nil
    }

    private func performProtocolNegotiation() async throws -> NegotiatedSession {
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

        var negotiatedSession = NegotiatedSession()
        negotiatedSession.negotiatedProtocol = negotiatedProtocol
        negotiatedSession.serverSoftwareVersion = version.serverVersion
        state.negotiatedSession.negotiatedProtocol = negotiatedSession.negotiatedProtocol
        state.negotiatedSession.serverSoftwareVersion = negotiatedSession.serverSoftwareVersion

        if let features = try? await fetchServerFeatures() {
            negotiatedSession.serverFeatures = features
            state.negotiatedSession.serverFeatures = features
        }

        return negotiatedSession
    }

    private func fetchServerFeatures() async throws -> ServerFeatures {
        let (_, features): (UUID, ServerFeatures) = try await call(method: .server(.features))
        return features
    }
}

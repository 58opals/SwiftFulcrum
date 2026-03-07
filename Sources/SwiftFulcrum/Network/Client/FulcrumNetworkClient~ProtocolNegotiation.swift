// FulcrumNetworkClient~ProtocolNegotiation.swift

import Foundation

extension FulcrumNetworkClient {
    func ensureNegotiatedProtocol() async throws -> NegotiatedSession {
        if state.negotiatedSession.negotiatedProtocol != nil {
            return state.negotiatedSession
        }
        
        if let negotiationTask = state.negotiatedSession.negotiationTask {
            return try await negotiationTask.value
        }
        
        let negotiationTask = Task { try await self.performProtocolNegotiation() }
        state.negotiatedSession.negotiationTask = negotiationTask
        
        do {
            let negotiatedSession = try await negotiationTask.value
            state.negotiatedSession.negotiatedProtocol = negotiatedSession.negotiatedProtocol
            state.negotiatedSession.serverSoftwareVersion = negotiatedSession.serverSoftwareVersion
            state.negotiatedSession.serverFeatures = negotiatedSession.serverFeatures
            state.negotiatedSession.negotiationTask = nil
            return negotiatedSession
        } catch {
            state.negotiatedSession.negotiatedProtocol = nil
            state.negotiatedSession.serverSoftwareVersion = nil
            state.negotiatedSession.serverFeatures = nil
            state.negotiatedSession.negotiationTask = nil
            throw error
        }
    }
    
    private func performProtocolNegotiation() async throws -> NegotiatedSession {
        let negotiationArgument = try protocolNegotiation.argument
        let supportedRange = try protocolNegotiation.supportedRange
        
        let (_, version): (UUID, SwiftFulcrum.RPC.Response.Result.Server.Version) = try await call(
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

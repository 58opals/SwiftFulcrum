// FulcrumNetworkClient~AutomaticReconnectRecoveryLifecycle.swift

import Foundation

extension FulcrumNetworkClient {
    func clearAutomaticReconnectRecoveryNeed() {
        automaticReconnectRecoveryPredecessorTask = nil
        automaticReconnectRecoverySuccessCount = nil
        automaticReconnectRecoveryGeneration = nil
        reconnectRecoveryTaskGenerationIdentifier = nil
        reconnectRecoveryState = .idle
    }

    func cancelAutomaticReconnectRecoveryTask() async {
        let predecessorTask = automaticReconnectRecoveryPredecessorTask
        automaticReconnectRecoveryPredecessorTask = nil

        guard let recoveryTask = reconnectRecoveryState.recoveryTask else {
            predecessorTask?.cancel()
            _ = await predecessorTask?.result
            automaticReconnectRecoverySuccessCount = nil
            automaticReconnectRecoveryGeneration = nil
            reconnectRecoveryTaskGenerationIdentifier = nil
            reconnectRecoveryState = .idle
            return
        }
        guard let generationIdentifier =
                reconnectRecoveryTaskGenerationIdentifier else {
            recoveryTask.cancel()
            _ = try? await recoveryTask.value
            predecessorTask?.cancel()
            _ = await predecessorTask?.result
            automaticReconnectRecoverySuccessCount = nil
            automaticReconnectRecoveryGeneration = nil
            reconnectRecoveryState = .idle
            return
        }

        recoveryTask.cancel()
        _ = try? await recoveryTask.value
        predecessorTask?.cancel()
        _ = await predecessorTask?.result
        if isCurrentAutomaticReconnectRecovery(
            generationIdentifier: generationIdentifier
        ) {
            automaticReconnectRecoverySuccessCount = nil
            automaticReconnectRecoveryGeneration = nil
            reconnectRecoveryTaskGenerationIdentifier = nil
            reconnectRecoveryState = .idle
        }
    }

    func isCurrentAutomaticReconnectRecovery(
        generationIdentifier: UUID,
        recoveryGeneration: UInt64? = nil
    ) -> Bool {
        guard reconnectRecoveryTaskGenerationIdentifier
                == generationIdentifier else {
            return false
        }
        guard let recoveryGeneration else { return true }
        return automaticReconnectRecoveryGeneration == recoveryGeneration
            && connectionRecoveryGeneration == recoveryGeneration
    }
}

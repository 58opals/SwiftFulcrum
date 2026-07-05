// FulcrumNetworkClient+SubscriptionRegistry.swift

import Foundation

extension FulcrumNetworkClient {
    struct SubscriptionRegistry: Sendable {
        private var records: [SubscriptionKey: SubscriptionRecord] = .init()
        private var cleanupTasks: [SubscriptionKey: Task<Bool, Never>] = .init()

        var count: Int { records.count }

        func makeRecords() -> [SubscriptionKey: SubscriptionRecord] {
            records
        }

        func makeStoredMethods() -> [(key: SubscriptionKey, method: SwiftFulcrum.RPC.Method)] {
            records.map { (key: $0.key, method: $0.value.method) }
        }

        func method(for key: SubscriptionKey) -> SwiftFulcrum.RPC.Method? {
            records[key]?.method
        }

        func cleanupTask(for key: SubscriptionKey) -> Task<Bool, Never>? {
            cleanupTasks[key]
        }

        func makeCleanupTasks() -> [Task<Bool, Never>] {
            Array(cleanupTasks.values)
        }

        mutating func recordCleanupTask(_ task: Task<Bool, Never>, for key: SubscriptionKey) {
            cleanupTasks[key] = task
        }

        mutating func removeCleanupTask(for key: SubscriptionKey) {
            cleanupTasks.removeValue(forKey: key)
        }

        mutating func recordPending(
            _ requestIdentifier: UUID,
            method: SwiftFulcrum.RPC.Method,
            for key: SubscriptionKey
        ) {
            records[key] = SubscriptionRecord(
                method: method,
                phase: .pending(requestIdentifier: requestIdentifier),
                cancellationRegistration: records[key]?.cancellationRegistration
            )
        }

        mutating func recordSetup(
            _ requestIdentifier: UUID,
            task: Task<Void, Swift.Error>? = nil,
            for key: SubscriptionKey
        ) {
            guard var record = records[key] else { return }
            record.phase = .settingUp(requestIdentifier: requestIdentifier, task: task)
            records[key] = record
        }

        mutating func recordActive(_ requestIdentifier: UUID, for key: SubscriptionKey) {
            guard var record = records[key] else { return }
            record.phase = .active(requestIdentifier: requestIdentifier)
            records[key] = record
        }

        mutating func clearPending(_ requestIdentifier: UUID, for key: SubscriptionKey) {
            guard case .pending(requestIdentifier) = records[key]?.phase else { return }
            records.removeValue(forKey: key)
        }

        mutating func clearSetup(_ requestIdentifier: UUID, for key: SubscriptionKey) {
            guard records[key]?.phase.requestIdentifier == requestIdentifier else { return }
            recordActive(requestIdentifier, for: key)
        }

        func isCurrentPendingRequest(_ requestIdentifier: UUID, for key: SubscriptionKey) -> Bool {
            guard case .pending(requestIdentifier) = records[key]?.phase else { return false }
            return true
        }

        func isCurrentSetupRequest(_ requestIdentifier: UUID, for key: SubscriptionKey) -> Bool {
            guard case .settingUp(requestIdentifier, _) = records[key]?.phase else { return false }
            return true
        }

        func isCurrentRoutableRequest(_ requestIdentifier: UUID, for key: SubscriptionKey) -> Bool {
            guard let phase = records[key]?.phase else { return false }
            return phase.isRoutable && phase.requestIdentifier == requestIdentifier
        }

        func acceptsCleanupRequest(
            _ requestIdentifier: UUID,
            for key: SubscriptionKey,
            requiringRoutableRequest: Bool
        ) -> Bool {
            guard let record = records[key] else { return false }
            let matchesRecord = record.phase.requestIdentifier == requestIdentifier ||
                record.originRequestIdentifier == requestIdentifier
            guard matchesRecord else { return false }
            return !requiringRoutableRequest || record.phase.isRoutable
        }

        func isCurrentRequest(_ requestIdentifier: UUID, for key: SubscriptionKey) -> Bool {
            records[key]?.phase.requestIdentifier == requestIdentifier
        }

        func isCurrentOriginRequest(_ requestIdentifier: UUID, for key: SubscriptionKey) -> Bool {
            records[key]?.originRequestIdentifier == requestIdentifier
        }

        func shouldSendUnsubscribeOnCancellation(for key: SubscriptionKey) -> Bool {
            records[key]?.phase.allowsUnsubscribeOnCancellation == true
        }

        func shouldSendDeferredUnsubscribe(for key: SubscriptionKey) -> Bool {
            records[key] == nil
        }

        mutating func cancelSetupRequest(
            for key: SubscriptionKey,
            expectedRequestIdentifier: UUID? = nil
        ) -> (requestIdentifier: UUID, task: Task<Void, Swift.Error>?)? {
            guard let record = records[key] else { return nil }
            guard case .settingUp(let requestIdentifier, let task) = record.phase else { return nil }
            if let expectedRequestIdentifier, requestIdentifier != expectedRequestIdentifier {
                return nil
            }

            records[key]?.phase = .active(requestIdentifier: requestIdentifier)
            task?.cancel()
            return (requestIdentifier, task)
        }

        @discardableResult
        mutating func removeRecord(
            for key: SubscriptionKey,
            requestIdentifier: UUID,
            requiringRoutableRequest: Bool
        ) -> SubscriptionRecord? {
            guard acceptsCleanupRequest(
                requestIdentifier,
                for: key,
                requiringRoutableRequest: requiringRoutableRequest
            ) else {
                return nil
            }

            return records.removeValue(forKey: key)
        }

        mutating func recordCancellationRegistration(
            _ cancellationRegistration: SubscriptionCancellationRegistration,
            for key: SubscriptionKey
        ) -> SubscriptionCancellationRegistration? {
            let existingRegistration = records[key]?.cancellationRegistration
            records[key]?.cancellationRegistration = cancellationRegistration
            return existingRegistration
        }

        mutating func removeCancellationRegistration(
            for key: SubscriptionKey
        ) -> SubscriptionCancellationRegistration? {
            guard let cancellationRegistration = records[key]?.cancellationRegistration else {
                return nil
            }

            records[key]?.cancellationRegistration = nil
            return cancellationRegistration
        }

        mutating func removeAllRecords() -> (
            setupTasks: [Task<Void, Swift.Error>],
            cleanupTasks: [Task<Bool, Never>],
            cancellationRegistrations: [SubscriptionCancellationRegistration],
            didRemoveStoredSubscriptions: Bool
        ) {
            let setupTasks = records.values.compactMap(\.phase.setupTask)
            let cancellationRegistrations = records.values.compactMap(\.cancellationRegistration)
            let cleanupTasks = Array(cleanupTasks.values)
            let didRemoveStoredSubscriptions = !records.isEmpty

            records.removeAll(keepingCapacity: false)
            self.cleanupTasks.removeAll(keepingCapacity: false)

            return (setupTasks, cleanupTasks, cancellationRegistrations, didRemoveStoredSubscriptions)
        }
    }
}

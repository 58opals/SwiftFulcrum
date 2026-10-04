// FulcrumNetworkClient+SubscriptionRestoreContext.swift

import Foundation
import Synchronization

extension FulcrumNetworkClient {
    final class ConnectionRecoveryGeneration: Equatable, Sendable {
        private let current: Mutex<UInt64>

        init(_ generation: UInt64 = 0) { current = Mutex(generation) }

        var value: UInt64 { current.withLock { $0 } }

        func advance() -> UInt64 {
            current.withLock { generation in
                generation &+= 1
                return generation
            }
        }

        func publishIfCurrent(_ generation: UInt64, publication: () -> Void) {
            current.withLock { current in
                guard current == generation, !Task.isCancelled else { return }
                publication()
            }
        }

        static func == (lhs: ConnectionRecoveryGeneration, rhs: ConnectionRecoveryGeneration) -> Bool {
            lhs === rhs
        }
    }

    struct SubscriptionRestoreContext: Equatable, Sendable {
        let subscriptionKey: SubscriptionKey
        let requestIdentifier: UUID
        let streamRegistrationIdentifier: UUID
        let reconnectSuccessCount: Int
        let recoveryGeneration: UInt64
        let recoveryGenerationAuthority: ConnectionRecoveryGeneration

        func makeNotification(from response: Data) throws -> Data? {
            guard case .regular = try SwiftFulcrum.RPC.Response.JSONRPC.classifyErasedResponse(from: response) else {
                return nil
            }
            // Restore uses the same result contract as the original subscription setup.
            switch subscriptionKey.methodPath {
            case .scriptHash:
                _ = try response.decode(SwiftFulcrum.Response.Blockchain.ScriptHash.Subscribe.self)
            case .address:
                _ = try response.decode(SwiftFulcrum.Response.Blockchain.Address.Subscribe.self)
            case .headers:
                _ = try response.decode(SwiftFulcrum.Response.Blockchain.Headers.Subscribe.self)
            case .transaction:
                _ = try response.decode(SwiftFulcrum.Response.Blockchain.Transaction.Subscribe.self)
            case .transactionDoubleSpendProof:
                _ = try response.decode(SwiftFulcrum.Response.Blockchain.Transaction.DSProof.Subscribe.self)
            }

            guard let object = try JSONSerialization.jsonObject(with: response) as? [String: Any],
                  let result = object["result"] else {
                throw JSONRPCResponseDecodeError.wrongResponseType
            }
            let parameters: [Any]
            if subscriptionKey.methodPath == .headers {
                parameters = [result]
            } else {
                guard let identifier = subscriptionKey.identifier else {
                    throw ResponseResultDecodeError.missingField("subscriptionIdentifier")
                }
                parameters = [identifier, result]
            }
            return try JSONSerialization.data(withJSONObject: [
                "jsonrpc": "2.0",
                "method": subscriptionKey.methodPath.rawValue,
                "params": parameters
            ])
        }
    }
}

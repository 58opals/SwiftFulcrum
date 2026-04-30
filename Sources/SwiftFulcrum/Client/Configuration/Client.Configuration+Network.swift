// Client.Configuration+Network.swift

import Foundation

extension SwiftFulcrum.Client.Configuration {
    public enum Network: Sendable {
        case mainnet
        case testnet
        case chipnet

        var resourceName: String {
            switch self {
            case .mainnet: return "servers.mainnet"
            case .testnet: return "servers.testnet"
            case .chipnet: return "servers.chipnet"
            }
        }
    }
}

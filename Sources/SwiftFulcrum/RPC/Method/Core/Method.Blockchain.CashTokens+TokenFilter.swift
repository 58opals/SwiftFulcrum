// Method.Blockchain.CashTokens+TokenFilter.swift

import Foundation

extension SwiftFulcrum.RPC.Method.Blockchain.CashTokens {
    public enum TokenFilter: String, Codable, Sendable {
        case include = "include_tokens"
        case exclude = "exclude_tokens"
        case only = "tokens_only"
    }
}

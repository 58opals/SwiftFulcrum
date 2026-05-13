// SwiftFulcrum.CashTokens+TokenFilter.swift

extension SwiftFulcrum.CashTokens {
    public enum TokenFilter: String, Codable, Sendable {
        case include = "include_tokens"
        case exclude = "exclude_tokens"
        case only = "tokens_only"
    }
}

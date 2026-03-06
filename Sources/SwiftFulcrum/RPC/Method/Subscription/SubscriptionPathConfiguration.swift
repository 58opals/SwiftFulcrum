enum SubscriptionPathConfiguration: String, CaseIterable, Sendable {
    case scriptHash = "blockchain.scripthash.subscribe"
    case address = "blockchain.address.subscribe"
    case headers = "blockchain.headers.subscribe"
    case transaction = "blockchain.transaction.subscribe"
    case transactionDoubleSpendProof = "blockchain.transaction.dsproof.subscribe"
}

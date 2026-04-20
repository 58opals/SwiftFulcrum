// Method+Blockchain.swift

import Foundation

extension SwiftFulcrum.RPC.Method {
    public enum Blockchain: Sendable {
        case estimateFee(numberOfBlocks: Int)
        case relayFee
        case scripthash(ScriptHash)
        case address(Address)
        case block(Block)
        case header(Header)
        case headers(Headers)
        case transaction(Transaction)
        case utxo(UTXO)
    }
}

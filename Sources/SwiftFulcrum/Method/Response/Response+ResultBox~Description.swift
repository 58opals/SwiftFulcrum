import Foundation

extension Response.Result.Box: CustomStringConvertible {
    var description: String {
        let storage =
"""
→ <ResultStorage>:
    → Blockchain
    [R] EstimateFee: \(self.blockchain.estimateFee.results)
    [R] RelayFee: \(self.blockchain.relayFee.results)
        → Address
        [R] GetBalance: \(self.blockchain.address.getBalance.results)
        [R] GetFirstUse: \(self.blockchain.address.getFirstUse.results)
        [R] GetHistory: \(self.blockchain.address.getHistory.results)
        [R] GetMempool: \(self.blockchain.address.getMempool.results)
        [R] GetScriptHash: \(self.blockchain.address.getScriptHash.results)
        [R] ListUnspent: \(self.blockchain.address.listUnspent.results)
        [R] Subscribe: \(self.blockchain.address.subscribe.results)
        [S] Subscribe: \(self.blockchain.address.notification.notifications)
        [R] Unsubscribe: \(self.blockchain.address.unsubscribe.results)
        → Block
        [R] Header: \(self.blockchain.block.header.results)
        [R] Headers: \(self.blockchain.block.headers.results)
        → Header
        [R] Get: \(self.blockchain.header.get.results)
        → Headers
        [R] GetTip: \(self.blockchain.headers.getTip.results)
        [R] Subscribe: \(self.blockchain.headers.subscribe.results)
        [S] Subscribe: \(self.blockchain.headers.notification.notifications)
        [R] Unsubscribe: \(self.blockchain.headers.unsubscribe.results)
        → Transaction
        [R] Broadcast: \(self.blockchain.transaction.broadcast.results)
        [R] Get: \(self.blockchain.transaction.get.results)
        [R] GetConfirmedBlockHash: \(self.blockchain.transaction.getConfirmedBlockHash.results)
        [R] GetHeight: \(self.blockchain.transaction.getHeight.results)
        [R] GetMerkle: \(self.blockchain.transaction.getMerkle.results)
        [R] IDFromPos: \(self.blockchain.transaction.idFromPos.results)
        [R] Subscribe: \(self.blockchain.transaction.subscribe.results)
        [S] Subscribe: \(self.blockchain.transaction.notification.notifications)
        [R] Unsubscribe: \(self.blockchain.transaction.unsubscribe.results)
            → DSProof
            [R] Get: \(self.blockchain.transaction.dsProof.get.results)
            [R] List: \(self.blockchain.transaction.dsProof.list.results)
            [R] Subscribe: \(self.blockchain.transaction.dsProof.subscribe.results)
            [S] Subscribe: \(self.blockchain.transaction.dsProof.notification.notifications)
            [R] Unsubscribe: \(self.blockchain.transaction.dsProof.unsubscribe.results)
        → UTXO
        [R] GetInfo: \(self.blockchain.utxo.getInfo.results)
    → Mempool
    [R] GetFeeHistogram: \(self.mempool.getFeeHistogram.results)
"""
        return storage
    }
}

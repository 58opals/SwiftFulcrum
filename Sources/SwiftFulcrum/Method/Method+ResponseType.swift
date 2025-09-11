// Method+ResponseType.swift

import Foundation

extension Method {
    enum ResponseType {
        // Blockchain
        case BlockchainEstimateFee(Response.Result.Blockchain.EstimateFee)
        case BlockchainRelayFee(Response.Result.Blockchain.RelayFee)
        
        // Blockchain.ScriptHash
        case BlockchainScriptHashGetBalance(Response.Result.Blockchain.ScriptHash.GetBalance)
        case BlockchainScriptHashGetFirstUse(Response.Result.Blockchain.ScriptHash.GetFirstUse)
        case BlockchainScriptHashGetHistory(Response.Result.Blockchain.ScriptHash.GetHistory)
        case BlockchainScriptHashGetMempool(Response.Result.Blockchain.ScriptHash.GetMempool)
        case BlockchainScriptHashListUnspent(Response.Result.Blockchain.ScriptHash.ListUnspent)
        case BlockchainScriptHashSubscribe(Response.Result.Blockchain.ScriptHash.Subscribe)
        case BlockchainScriptHashUnsubscribe(Response.Result.Blockchain.ScriptHash.Unsubscribe)
        
        // Blockchain.Address
        case BlockchainAddressGetBalance(Response.Result.Blockchain.Address.GetBalance)
        case BlockchainAddressGetFirstUse(Response.Result.Blockchain.Address.GetFirstUse)
        case BlockchainAddressGetHistory(Response.Result.Blockchain.Address.GetHistory)
        case BlockchainAddressGetMempool(Response.Result.Blockchain.Address.GetMempool)
        case BlockchainAddressGetScriptHash(Response.Result.Blockchain.Address.GetScriptHash)
        case BlockchainAddressListUnspent(Response.Result.Blockchain.Address.ListUnspent)
        case BlockchainAddressSubscribe(Response.Result.Blockchain.Address.Subscribe)
        case BlockchainAddressUnsubscribe(Response.Result.Blockchain.Address.Unsubscribe)
        
        // Blockchain.Block
        case BlockchainBlockHeader(Response.Result.Blockchain.Block.Header)
        case BlockchainBlockHeaders(Response.Result.Blockchain.Block.Headers)
        
        // Blockchain.Header
        case BlockchainHeaderGet(Response.Result.Blockchain.Header.Get)
        
        // Blockchain.Headers
        case BlockchainHeadersGetTip(Response.Result.Blockchain.Headers.GetTip)
        case BlockchainHeadersSubscribe(Response.Result.Blockchain.Headers.Subscribe)
        case BlockchainHeadersUnsubscribe(Response.Result.Blockchain.Headers.Unsubscribe)
        
        // Blockchain.Transaction
        case BlockchainTransactionBroadcast(Response.Result.Blockchain.Transaction.Broadcast)
        case BlockchainTransactionGet(Response.Result.Blockchain.Transaction.Get)
        case BlockchainTransactionGetConfirmedBlockHash(Response.Result.Blockchain.Transaction.GetConfirmedBlockHash)
        case BlockchainTransactionGetHeight(Response.Result.Blockchain.Transaction.GetHeight)
        case BlockchainTransactionGetMerkle(Response.Result.Blockchain.Transaction.GetMerkle)
        case BlockchainTransactionIDFromPos(Response.Result.Blockchain.Transaction.IDFromPos)
        case BlockchainTransactionSubscribe(Response.Result.Blockchain.Transaction.Subscribe)
        case BlockchainTransactionUnsubscribe(Response.Result.Blockchain.Transaction.Unsubscribe)
        
        // Blockchain.Transaction.DSProof
        case BlockchainTransactionDSProofGet(Response.Result.Blockchain.Transaction.DSProof.Get)
        case BlockchainTransactionDSProofList(Response.Result.Blockchain.Transaction.DSProof.List)
        case BlockchainTransactionDSProofSubscribe(Response.Result.Blockchain.Transaction.DSProof.Subscribe)
        case BlockchainTransactionDSProofUnsubscribe(Response.Result.Blockchain.Transaction.DSProof.Unsubscribe)
        
        // Blockchain.UTXO
        case BlockchainUTXOGet(Response.Result.Blockchain.UTXO.GetInfo)
        
        // Mempool
        case MempoolGetFeeHistogram(Response.Result.Mempool.GetFeeHistogram)
    }
}

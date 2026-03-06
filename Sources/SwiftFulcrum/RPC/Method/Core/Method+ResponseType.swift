// Method+ResponseType.swift

import Foundation

extension SwiftFulcrum.RPC.Method {
    enum ResponseType {
        // Server
        case ServerPing(SwiftFulcrum.RPC.Response.Result.Server.Ping)
        case ServerVersion(SwiftFulcrum.RPC.Response.Result.Server.Version)
        case ServerFeatures(SwiftFulcrum.RPC.Response.Result.Server.Features)
        
        // Blockchain
        case BlockchainEstimateFee(SwiftFulcrum.RPC.Response.Result.Blockchain.EstimateFee)
        case BlockchainRelayFee(SwiftFulcrum.RPC.Response.Result.Blockchain.RelayFee)
        
        // Blockchain.ScriptHash
        case BlockchainScriptHashGetBalance(SwiftFulcrum.RPC.Response.Result.Blockchain.ScriptHash.GetBalance)
        case BlockchainScriptHashGetFirstUse(SwiftFulcrum.RPC.Response.Result.Blockchain.ScriptHash.GetFirstUse)
        case BlockchainScriptHashGetHistory(SwiftFulcrum.RPC.Response.Result.Blockchain.ScriptHash.GetHistory)
        case BlockchainScriptHashGetMempool(SwiftFulcrum.RPC.Response.Result.Blockchain.ScriptHash.GetMempool)
        case BlockchainScriptHashListUnspent(SwiftFulcrum.RPC.Response.Result.Blockchain.ScriptHash.ListUnspent)
        case BlockchainScriptHashSubscribe(SwiftFulcrum.RPC.Response.Result.Blockchain.ScriptHash.Subscribe)
        case BlockchainScriptHashUnsubscribe(SwiftFulcrum.RPC.Response.Result.Blockchain.ScriptHash.Unsubscribe)
        
        // Blockchain.Address
        case BlockchainAddressGetBalance(SwiftFulcrum.RPC.Response.Result.Blockchain.Address.GetBalance)
        case BlockchainAddressGetFirstUse(SwiftFulcrum.RPC.Response.Result.Blockchain.Address.GetFirstUse)
        case BlockchainAddressGetHistory(SwiftFulcrum.RPC.Response.Result.Blockchain.Address.GetHistory)
        case BlockchainAddressGetMempool(SwiftFulcrum.RPC.Response.Result.Blockchain.Address.GetMempool)
        case BlockchainAddressGetScriptHash(SwiftFulcrum.RPC.Response.Result.Blockchain.Address.GetScriptHash)
        case BlockchainAddressListUnspent(SwiftFulcrum.RPC.Response.Result.Blockchain.Address.ListUnspent)
        case BlockchainAddressSubscribe(SwiftFulcrum.RPC.Response.Result.Blockchain.Address.Subscribe)
        case BlockchainAddressUnsubscribe(SwiftFulcrum.RPC.Response.Result.Blockchain.Address.Unsubscribe)
        
        // Blockchain.Block
        case BlockchainBlockHeader(SwiftFulcrum.RPC.Response.Result.Blockchain.Block.Header)
        case BlockchainBlockHeaders(SwiftFulcrum.RPC.Response.Result.Blockchain.Block.Headers)
        
        // Blockchain.HeaderModel
        case BlockchainHeaderGet(SwiftFulcrum.RPC.Response.Result.Blockchain.Header.Get)
        
        // Blockchain.Headers
        case BlockchainHeadersGetTip(SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.GetTip)
        case BlockchainHeadersSubscribe(SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.Subscribe)
        case BlockchainHeadersUnsubscribe(SwiftFulcrum.RPC.Response.Result.Blockchain.Headers.Unsubscribe)
        
        // Blockchain.Transaction
        case BlockchainTransactionBroadcast(SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction.Broadcast)
        case BlockchainTransactionGet(SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction.Get)
        case BlockchainTransactionGetConfirmedBlockHash(SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction.GetConfirmedBlockHash)
        case BlockchainTransactionGetHeight(SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction.GetHeight)
        case BlockchainTransactionGetMerkle(SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction.GetMerkle)
        case BlockchainTransactionIDFromPos(SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction.IDFromPos)
        case BlockchainTransactionSubscribe(SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction.Subscribe)
        case BlockchainTransactionUnsubscribe(SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction.Unsubscribe)
        
        // Blockchain.Transaction.DSProof
        case BlockchainTransactionDSProofGet(SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction.DSProof.Get)
        case BlockchainTransactionDSProofList(SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction.DSProof.List)
        case BlockchainTransactionDSProofSubscribe(SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction.DSProof.Subscribe)
        case BlockchainTransactionDSProofUnsubscribe(SwiftFulcrum.RPC.Response.Result.Blockchain.Transaction.DSProof.Unsubscribe)
        
        // Blockchain.UTXO
        case BlockchainUTXOGet(SwiftFulcrum.RPC.Response.Result.Blockchain.UTXO.GetInfo)
        
        // Mempool
        case MempoolGetFeeHistogram(SwiftFulcrum.RPC.Response.Result.Mempool.GetFeeHistogram)
    }
}

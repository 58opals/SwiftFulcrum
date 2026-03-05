// SwiftFulcrum.RPC.Method+ResponseTypeModel.swift

import Foundation

extension SwiftFulcrum.RPC.Method {
    enum ResponseTypeModel {
        // ServerModel
        case ServerPing(SwiftFulcrum.RPC.Response.ResultModel.Server.Ping)
        case ServerVersion(SwiftFulcrum.RPC.Response.ResultModel.Server.Version)
        case ServerFeatures(SwiftFulcrum.RPC.Response.ResultModel.Server.Features)
        
        // BlockchainModel
        case BlockchainEstimateFee(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.EstimateFee)
        case BlockchainRelayFee(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.RelayFee)
        
        // BlockchainModel.ScriptHash
        case BlockchainScriptHashGetBalance(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.ScriptHash.GetBalance)
        case BlockchainScriptHashGetFirstUse(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.ScriptHash.GetFirstUse)
        case BlockchainScriptHashGetHistory(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.ScriptHash.GetHistory)
        case BlockchainScriptHashGetMempool(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.ScriptHash.GetMempool)
        case BlockchainScriptHashListUnspent(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.ScriptHash.ListUnspent)
        case BlockchainScriptHashSubscribe(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.ScriptHash.Subscribe)
        case BlockchainScriptHashUnsubscribe(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.ScriptHash.Unsubscribe)
        
        // BlockchainModel.Address
        case BlockchainAddressGetBalance(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Address.GetBalance)
        case BlockchainAddressGetFirstUse(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Address.GetFirstUse)
        case BlockchainAddressGetHistory(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Address.GetHistory)
        case BlockchainAddressGetMempool(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Address.GetMempool)
        case BlockchainAddressGetScriptHash(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Address.GetScriptHash)
        case BlockchainAddressListUnspent(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Address.ListUnspent)
        case BlockchainAddressSubscribe(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Address.Subscribe)
        case BlockchainAddressUnsubscribe(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Address.Unsubscribe)
        
        // BlockchainModel.Block
        case BlockchainBlockHeader(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Block.Header)
        case BlockchainBlockHeaders(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Block.Headers)
        
        // BlockchainModel.HeaderModel
        case BlockchainHeaderGet(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Header.Get)
        
        // BlockchainModel.Headers
        case BlockchainHeadersGetTip(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Headers.GetTip)
        case BlockchainHeadersSubscribe(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Headers.Subscribe)
        case BlockchainHeadersUnsubscribe(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Headers.Unsubscribe)
        
        // BlockchainModel.Transaction
        case BlockchainTransactionBroadcast(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Transaction.Broadcast)
        case BlockchainTransactionGet(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Transaction.Get)
        case BlockchainTransactionGetConfirmedBlockHash(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Transaction.GetConfirmedBlockHash)
        case BlockchainTransactionGetHeight(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Transaction.GetHeight)
        case BlockchainTransactionGetMerkle(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Transaction.GetMerkle)
        case BlockchainTransactionIDFromPos(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Transaction.IDFromPos)
        case BlockchainTransactionSubscribe(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Transaction.Subscribe)
        case BlockchainTransactionUnsubscribe(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Transaction.Unsubscribe)
        
        // BlockchainModel.Transaction.DSProof
        case BlockchainTransactionDSProofGet(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Transaction.DSProof.Get)
        case BlockchainTransactionDSProofList(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Transaction.DSProof.List)
        case BlockchainTransactionDSProofSubscribe(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Transaction.DSProof.Subscribe)
        case BlockchainTransactionDSProofUnsubscribe(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.Transaction.DSProof.Unsubscribe)
        
        // BlockchainModel.UTXO
        case BlockchainUTXOGet(SwiftFulcrum.RPC.Response.ResultModel.Blockchain.UTXO.GetInfo)
        
        // MempoolModel
        case MempoolGetFeeHistogram(SwiftFulcrum.RPC.Response.ResultModel.Mempool.GetFeeHistogram)
    }
}

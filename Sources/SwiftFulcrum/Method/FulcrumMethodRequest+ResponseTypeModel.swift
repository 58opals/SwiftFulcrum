// FulcrumMethodRequest+ResponseTypeModel.swift

import Foundation

extension FulcrumMethodRequest {
    enum ResponseTypeModel {
        // ServerModel
        case ServerPing(FulcrumResponse.ResultModel.Server.Ping)
        case ServerVersion(FulcrumResponse.ResultModel.Server.Version)
        case ServerFeatures(FulcrumResponse.ResultModel.Server.Features)
        
        // BlockchainModel
        case BlockchainEstimateFee(FulcrumResponse.ResultModel.Blockchain.EstimateFee)
        case BlockchainRelayFee(FulcrumResponse.ResultModel.Blockchain.RelayFee)
        
        // BlockchainModel.ScriptHash
        case BlockchainScriptHashGetBalance(FulcrumResponse.ResultModel.Blockchain.ScriptHash.GetBalance)
        case BlockchainScriptHashGetFirstUse(FulcrumResponse.ResultModel.Blockchain.ScriptHash.GetFirstUse)
        case BlockchainScriptHashGetHistory(FulcrumResponse.ResultModel.Blockchain.ScriptHash.GetHistory)
        case BlockchainScriptHashGetMempool(FulcrumResponse.ResultModel.Blockchain.ScriptHash.GetMempool)
        case BlockchainScriptHashListUnspent(FulcrumResponse.ResultModel.Blockchain.ScriptHash.ListUnspent)
        case BlockchainScriptHashSubscribe(FulcrumResponse.ResultModel.Blockchain.ScriptHash.Subscribe)
        case BlockchainScriptHashUnsubscribe(FulcrumResponse.ResultModel.Blockchain.ScriptHash.Unsubscribe)
        
        // BlockchainModel.Address
        case BlockchainAddressGetBalance(FulcrumResponse.ResultModel.Blockchain.Address.GetBalance)
        case BlockchainAddressGetFirstUse(FulcrumResponse.ResultModel.Blockchain.Address.GetFirstUse)
        case BlockchainAddressGetHistory(FulcrumResponse.ResultModel.Blockchain.Address.GetHistory)
        case BlockchainAddressGetMempool(FulcrumResponse.ResultModel.Blockchain.Address.GetMempool)
        case BlockchainAddressGetScriptHash(FulcrumResponse.ResultModel.Blockchain.Address.GetScriptHash)
        case BlockchainAddressListUnspent(FulcrumResponse.ResultModel.Blockchain.Address.ListUnspent)
        case BlockchainAddressSubscribe(FulcrumResponse.ResultModel.Blockchain.Address.Subscribe)
        case BlockchainAddressUnsubscribe(FulcrumResponse.ResultModel.Blockchain.Address.Unsubscribe)
        
        // BlockchainModel.Block
        case BlockchainBlockHeader(FulcrumResponse.ResultModel.Blockchain.Block.Header)
        case BlockchainBlockHeaders(FulcrumResponse.ResultModel.Blockchain.Block.Headers)
        
        // BlockchainModel.HeaderModel
        case BlockchainHeaderGet(FulcrumResponse.ResultModel.Blockchain.Header.Get)
        
        // BlockchainModel.Headers
        case BlockchainHeadersGetTip(FulcrumResponse.ResultModel.Blockchain.Headers.GetTip)
        case BlockchainHeadersSubscribe(FulcrumResponse.ResultModel.Blockchain.Headers.Subscribe)
        case BlockchainHeadersUnsubscribe(FulcrumResponse.ResultModel.Blockchain.Headers.Unsubscribe)
        
        // BlockchainModel.Transaction
        case BlockchainTransactionBroadcast(FulcrumResponse.ResultModel.Blockchain.Transaction.Broadcast)
        case BlockchainTransactionGet(FulcrumResponse.ResultModel.Blockchain.Transaction.Get)
        case BlockchainTransactionGetConfirmedBlockHash(FulcrumResponse.ResultModel.Blockchain.Transaction.GetConfirmedBlockHash)
        case BlockchainTransactionGetHeight(FulcrumResponse.ResultModel.Blockchain.Transaction.GetHeight)
        case BlockchainTransactionGetMerkle(FulcrumResponse.ResultModel.Blockchain.Transaction.GetMerkle)
        case BlockchainTransactionIDFromPos(FulcrumResponse.ResultModel.Blockchain.Transaction.IDFromPos)
        case BlockchainTransactionSubscribe(FulcrumResponse.ResultModel.Blockchain.Transaction.Subscribe)
        case BlockchainTransactionUnsubscribe(FulcrumResponse.ResultModel.Blockchain.Transaction.Unsubscribe)
        
        // BlockchainModel.Transaction.DSProof
        case BlockchainTransactionDSProofGet(FulcrumResponse.ResultModel.Blockchain.Transaction.DSProof.Get)
        case BlockchainTransactionDSProofList(FulcrumResponse.ResultModel.Blockchain.Transaction.DSProof.List)
        case BlockchainTransactionDSProofSubscribe(FulcrumResponse.ResultModel.Blockchain.Transaction.DSProof.Subscribe)
        case BlockchainTransactionDSProofUnsubscribe(FulcrumResponse.ResultModel.Blockchain.Transaction.DSProof.Unsubscribe)
        
        // BlockchainModel.UTXO
        case BlockchainUTXOGet(FulcrumResponse.ResultModel.Blockchain.UTXO.GetInfo)
        
        // MempoolModel
        case MempoolGetFeeHistogram(FulcrumResponse.ResultModel.Mempool.GetFeeHistogram)
    }
}

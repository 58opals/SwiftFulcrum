import Foundation

extension Method {
    enum ResponseType {
        // Blockchain
        case BlockchainEstimateFee(Response.Result.Blockchain.EstimateFeeJSONRPCResult)
        case BlockchainRelayFee(Response.Result.Blockchain.RelayFeeJSONRPCResult)
        
        // Blockchain.Address
        case BlockchainAddressGetBalance(Response.Result.Blockchain.Address.GetBalanceJSONRPCResult)
        case BlockchainAddressGetFirstUse(Response.Result.Blockchain.Address.GetFirstUseJSONRPCResult)
        case BlockchainAddressGetHistory(Response.Result.Blockchain.Address.GetHistoryJSONRPCResult)
        case BlockchainAddressGetMempool(Response.Result.Blockchain.Address.GetMempoolJSONRPCResult)
        case BlockchainAddressGetScriptHash(Response.Result.Blockchain.Address.GetScriptHashJSONRPCResult)
        case BlockchainAddressListUnspent(Response.Result.Blockchain.Address.ListUnspentJSONRPCResult)
        case BlockchainAddressSubscribe(Response.Result.Blockchain.Address.SubscribeJSONRPCResult)
        case BlockchainAddressUnsubscribe(Response.Result.Blockchain.Address.UnsubscribeJSONRPCResult)
        
        // Blockchain.Block
        case BlockchainBlockHeader(Response.Result.Blockchain.Block.HeaderJSONRPCResult)
        case BlockchainBlockHeaders(Response.Result.Blockchain.Block.HeadersJSONRPCResult)
        
        // Blockchain.Header
        case BlockchainHeaderGet(Response.Result.Blockchain.Header.GetJSONRPCResult)
        
        // Blockchain.Headers
        case BlockchainHeadersGetTip(Response.Result.Blockchain.Headers.GetTipJSONRPCResult)
        case BlockchainHeadersSubscribe(Response.Result.Blockchain.Headers.SubscribeJSONRPCResult)
        case BlockchainHeadersUnsubscribe(Response.Result.Blockchain.Headers.UnsubscribeJSONRPCResult)
        
        // Blockchain.Transaction
        case BlockchainTransactionBroadcast(Response.Result.Blockchain.Transaction.BroadcastJSONRPCResult)
        case BlockchainTransactionGet(Response.Result.Blockchain.Transaction.GetJSONRPCResult)
        case BlockchainTransactionGetConfirmedBlockHash(Response.Result.Blockchain.Transaction.GetConfirmedBlockHashJSONRPCResult)
        case BlockchainTransactionGetHeight(Response.Result.Blockchain.Transaction.GetHeightJSONRPCResult)
        case BlockchainTransactionGetMerkle(Response.Result.Blockchain.Transaction.GetMerkleJSONRPCResult)
        case BlockchainTransactionIDFromPos(Response.Result.Blockchain.Transaction.IDFromPosJSONRPCResult)
        case BlockchainTransactionSubscribe(Response.Result.Blockchain.Transaction.SubscribeJSONRPCResult)
        case BlockchainTransactionUnsubscribe(Response.Result.Blockchain.Transaction.UnsubscribeJSONRPCResult)
        
        // Blockchain.Transaction.DSProof
        case BlockchainTransactionDSProofGet(Response.Result.Blockchain.Transaction.DSProof.GetJSONRPCResult)
        case BlockchainTransactionDSProofList(Response.Result.Blockchain.Transaction.DSProof.ListJSONRPCResult)
        case BlockchainTransactionDSProofSubscribe(Response.Result.Blockchain.Transaction.DSProof.SubscribeJSONRPCResult)
        case BlockchainTransactionDSProofUnsubscribe(Response.Result.Blockchain.Transaction.DSProof.UnsubscribeJSONRPCResult)
        
        // Blockchain.UTXO
        case BlockchainUTXOGet(Response.Result.Blockchain.UTXO.GetInfoJSONRPCResult)
        
        // Mempool
        case MempoolGetFeeHistogram(Response.Result.Mempool.GetFeeHistogramJSONRPCResult)
    }
}

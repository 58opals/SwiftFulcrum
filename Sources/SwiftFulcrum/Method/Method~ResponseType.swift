import Foundation

extension Method {
    enum ResponseType {
        // Blockchain
        case BlockchainEstimateFee(Response.JSONRPC.Result.Blockchain.EstimateFee)
        case BlockchainRelayFee(Response.JSONRPC.Result.Blockchain.RelayFee)
        
        // Blockchain.Address
        case BlockchainAddressGetBalance(Response.JSONRPC.Result.Blockchain.Address.GetBalance)
        case BlockchainAddressGetFirstUse(Response.JSONRPC.Result.Blockchain.Address.GetFirstUse)
        case BlockchainAddressGetHistory(Response.JSONRPC.Result.Blockchain.Address.GetHistory)
        case BlockchainAddressGetMempool(Response.JSONRPC.Result.Blockchain.Address.GetMempool)
        case BlockchainAddressGetScriptHash(Response.JSONRPC.Result.Blockchain.Address.GetScriptHash)
        case BlockchainAddressListUnspent(Response.JSONRPC.Result.Blockchain.Address.ListUnspent)
        case BlockchainAddressSubscribe(Response.JSONRPC.Result.Blockchain.Address.Subscribe)
        case BlockchainAddressSubscribeNotification(Response.JSONRPC.Result.Blockchain.Address.SubscribeNotification)
        case BlockchainAddressUnsubscribe(Response.JSONRPC.Result.Blockchain.Address.Unsubscribe)
        
        // Blockchain.Block
        case BlockchainBlockHeader(Response.JSONRPC.Result.Blockchain.Block.Header)
        case BlockchainBlockHeaders(Response.JSONRPC.Result.Blockchain.Block.Headers)
        
        // Blockchain.Header
        case BlockchainHeaderGet(Response.JSONRPC.Result.Blockchain.Header.Get)
        
        // Blockchain.Headers
        case BlockchainHeadersGetTip(Response.JSONRPC.Result.Blockchain.Headers.GetTip)
        case BlockchainHeadersSubscribe(Response.JSONRPC.Result.Blockchain.Headers.Subscribe)
        case BlockchainHeadersSubscribeNotification(Response.JSONRPC.Result.Blockchain.Headers.SubscribeNotification)
        case BlockchainHeadersUnsubscribe(Response.JSONRPC.Result.Blockchain.Headers.Unsubscribe)
        
        // Blockchain.Transaction
        case BlockchainTransactionBroadcast(Response.JSONRPC.Result.Blockchain.Transaction.Broadcast)
        case BlockchainTransactionGet(Response.JSONRPC.Result.Blockchain.Transaction.Get)
        case BlockchainTransactionGetConfirmedBlockHash(Response.JSONRPC.Result.Blockchain.Transaction.GetConfirmedBlockHash)
        case BlockchainTransactionGetHeight(Response.JSONRPC.Result.Blockchain.Transaction.GetHeight)
        case BlockchainTransactionGetMerkle(Response.JSONRPC.Result.Blockchain.Transaction.GetMerkle)
        case BlockchainTransactionIDFromPos(Response.JSONRPC.Result.Blockchain.Transaction.IDFromPos)
        case BlockchainTransactionSubscribe(Response.JSONRPC.Result.Blockchain.Transaction.Subscribe)
        case BlockchainTransactionSubscribeNotification(Response.JSONRPC.Result.Blockchain.Transaction.SubscribeNotification)
        case BlockchainTransactionUnsubscribe(Response.JSONRPC.Result.Blockchain.Transaction.Unsubscribe)
        
        // Blockchain.Transaction.DSProof
        case BlockchainTransactionDSProofGet(Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Get)
        case BlockchainTransactionDSProofList(Response.JSONRPC.Result.Blockchain.Transaction.DSProof.List)
        case BlockchainTransactionDSProofSubscribe(Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Subscribe)
        case BlockchainTransactionDSProofSubscribeNotification(Response.JSONRPC.Result.Blockchain.Transaction.DSProof.SubscribeNotification)
        case BlockchainTransactionDSProofUnsubscribe(Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Unsubscribe)
        
        // Blockchain.UTXO
        case BlockchainUTXOGet(Response.JSONRPC.Result.Blockchain.UTXO.GetInfo)
        
        // Mempool
        case MempoolGetFeeHistogram(Response.JSONRPC.Result.Mempool.GetFeeHistogram)
    }
}

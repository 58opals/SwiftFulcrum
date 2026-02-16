// FulcrumMethodRequest+ResponseTypeModel.swift

import Foundation

extension FulcrumMethodRequest {
    enum ResponseTypeModel {
        // ServerModel
        case ServerPing(Response.ResultModel.ServerModel.PingModel)
        case ServerVersion(Response.ResultModel.ServerModel.VersionModel)
        case ServerFeatures(Response.ResultModel.ServerModel.FeaturesModel)
        
        // BlockchainModel
        case BlockchainEstimateFee(Response.ResultModel.BlockchainModel.EstimateFeeModel)
        case BlockchainRelayFee(Response.ResultModel.BlockchainModel.RelayFeeModel)
        
        // BlockchainModel.ScriptHashModel
        case BlockchainScriptHashGetBalance(Response.ResultModel.BlockchainModel.ScriptHashModel.GetBalanceModel)
        case BlockchainScriptHashGetFirstUse(Response.ResultModel.BlockchainModel.ScriptHashModel.GetFirstUseModel)
        case BlockchainScriptHashGetHistory(Response.ResultModel.BlockchainModel.ScriptHashModel.GetHistoryModel)
        case BlockchainScriptHashGetMempool(Response.ResultModel.BlockchainModel.ScriptHashModel.GetMempoolModel)
        case BlockchainScriptHashListUnspent(Response.ResultModel.BlockchainModel.ScriptHashModel.ListUnspentModel)
        case BlockchainScriptHashSubscribe(Response.ResultModel.BlockchainModel.ScriptHashModel.SubscribeModel)
        case BlockchainScriptHashUnsubscribe(Response.ResultModel.BlockchainModel.ScriptHashModel.UnsubscribeModel)
        
        // BlockchainModel.AddressModel
        case BlockchainAddressGetBalance(Response.ResultModel.BlockchainModel.AddressModel.GetBalanceModel)
        case BlockchainAddressGetFirstUse(Response.ResultModel.BlockchainModel.AddressModel.GetFirstUseModel)
        case BlockchainAddressGetHistory(Response.ResultModel.BlockchainModel.AddressModel.GetHistoryModel)
        case BlockchainAddressGetMempool(Response.ResultModel.BlockchainModel.AddressModel.GetMempoolModel)
        case BlockchainAddressGetScriptHash(Response.ResultModel.BlockchainModel.AddressModel.GetScriptHashModel)
        case BlockchainAddressListUnspent(Response.ResultModel.BlockchainModel.AddressModel.ListUnspentModel)
        case BlockchainAddressSubscribe(Response.ResultModel.BlockchainModel.AddressModel.SubscribeModel)
        case BlockchainAddressUnsubscribe(Response.ResultModel.BlockchainModel.AddressModel.UnsubscribeModel)
        
        // BlockchainModel.BlockModel
        case BlockchainBlockHeader(Response.ResultModel.BlockchainModel.BlockModel.HeaderModel)
        case BlockchainBlockHeaders(Response.ResultModel.BlockchainModel.BlockModel.HeadersModel)
        
        // BlockchainModel.HeaderModel
        case BlockchainHeaderGet(Response.ResultModel.BlockchainModel.HeaderModel.GetModel)
        
        // BlockchainModel.HeadersModel
        case BlockchainHeadersGetTip(Response.ResultModel.BlockchainModel.HeadersModel.GetTipModel)
        case BlockchainHeadersSubscribe(Response.ResultModel.BlockchainModel.HeadersModel.SubscribeModel)
        case BlockchainHeadersUnsubscribe(Response.ResultModel.BlockchainModel.HeadersModel.UnsubscribeModel)
        
        // BlockchainModel.TransactionModel
        case BlockchainTransactionBroadcast(Response.ResultModel.BlockchainModel.TransactionModel.BroadcastModel)
        case BlockchainTransactionGet(Response.ResultModel.BlockchainModel.TransactionModel.GetModel)
        case BlockchainTransactionGetConfirmedBlockHash(Response.ResultModel.BlockchainModel.TransactionModel.GetConfirmedBlockHashModel)
        case BlockchainTransactionGetHeight(Response.ResultModel.BlockchainModel.TransactionModel.GetHeightModel)
        case BlockchainTransactionGetMerkle(Response.ResultModel.BlockchainModel.TransactionModel.GetMerkleModel)
        case BlockchainTransactionIDFromPos(Response.ResultModel.BlockchainModel.TransactionModel.IDFromPosModel)
        case BlockchainTransactionSubscribe(Response.ResultModel.BlockchainModel.TransactionModel.SubscribeModel)
        case BlockchainTransactionUnsubscribe(Response.ResultModel.BlockchainModel.TransactionModel.UnsubscribeModel)
        
        // BlockchainModel.TransactionModel.DSProofModel
        case BlockchainTransactionDSProofGet(Response.ResultModel.BlockchainModel.TransactionModel.DSProofModel.GetModel)
        case BlockchainTransactionDSProofList(Response.ResultModel.BlockchainModel.TransactionModel.DSProofModel.ListModel)
        case BlockchainTransactionDSProofSubscribe(Response.ResultModel.BlockchainModel.TransactionModel.DSProofModel.SubscribeModel)
        case BlockchainTransactionDSProofUnsubscribe(Response.ResultModel.BlockchainModel.TransactionModel.DSProofModel.UnsubscribeModel)
        
        // BlockchainModel.UTXOModel
        case BlockchainUTXOGet(Response.ResultModel.BlockchainModel.UTXOModel.GetInfoModel)
        
        // MempoolModel
        case MempoolGetFeeHistogram(Response.ResultModel.MempoolModel.GetFeeHistogramModel)
    }
}

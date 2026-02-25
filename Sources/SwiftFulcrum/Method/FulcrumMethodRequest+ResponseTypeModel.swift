// FulcrumMethodRequest+ResponseTypeModel.swift

import Foundation

extension FulcrumMethodRequest {
    enum ResponseTypeModel {
        // ServerModel
        case ServerPing(FulcrumResponse.ResultModel.ServerModel.PingModel)
        case ServerVersion(FulcrumResponse.ResultModel.ServerModel.VersionModel)
        case ServerFeatures(FulcrumResponse.ResultModel.ServerModel.FeaturesModel)
        
        // BlockchainModel
        case BlockchainEstimateFee(FulcrumResponse.ResultModel.BlockchainModel.EstimateFeeModel)
        case BlockchainRelayFee(FulcrumResponse.ResultModel.BlockchainModel.RelayFeeModel)
        
        // BlockchainModel.ScriptHashModel
        case BlockchainScriptHashGetBalance(FulcrumResponse.ResultModel.BlockchainModel.ScriptHashModel.GetBalanceModel)
        case BlockchainScriptHashGetFirstUse(FulcrumResponse.ResultModel.BlockchainModel.ScriptHashModel.GetFirstUseModel)
        case BlockchainScriptHashGetHistory(FulcrumResponse.ResultModel.BlockchainModel.ScriptHashModel.GetHistoryModel)
        case BlockchainScriptHashGetMempool(FulcrumResponse.ResultModel.BlockchainModel.ScriptHashModel.GetMempoolModel)
        case BlockchainScriptHashListUnspent(FulcrumResponse.ResultModel.BlockchainModel.ScriptHashModel.ListUnspentModel)
        case BlockchainScriptHashSubscribe(FulcrumResponse.ResultModel.BlockchainModel.ScriptHashModel.SubscribeModel)
        case BlockchainScriptHashUnsubscribe(FulcrumResponse.ResultModel.BlockchainModel.ScriptHashModel.UnsubscribeModel)
        
        // BlockchainModel.AddressModel
        case BlockchainAddressGetBalance(FulcrumResponse.ResultModel.BlockchainModel.AddressModel.GetBalanceModel)
        case BlockchainAddressGetFirstUse(FulcrumResponse.ResultModel.BlockchainModel.AddressModel.GetFirstUseModel)
        case BlockchainAddressGetHistory(FulcrumResponse.ResultModel.BlockchainModel.AddressModel.GetHistoryModel)
        case BlockchainAddressGetMempool(FulcrumResponse.ResultModel.BlockchainModel.AddressModel.GetMempoolModel)
        case BlockchainAddressGetScriptHash(FulcrumResponse.ResultModel.BlockchainModel.AddressModel.GetScriptHashModel)
        case BlockchainAddressListUnspent(FulcrumResponse.ResultModel.BlockchainModel.AddressModel.ListUnspentModel)
        case BlockchainAddressSubscribe(FulcrumResponse.ResultModel.BlockchainModel.AddressModel.SubscribeModel)
        case BlockchainAddressUnsubscribe(FulcrumResponse.ResultModel.BlockchainModel.AddressModel.UnsubscribeModel)
        
        // BlockchainModel.BlockModel
        case BlockchainBlockHeader(FulcrumResponse.ResultModel.BlockchainModel.BlockModel.HeaderModel)
        case BlockchainBlockHeaders(FulcrumResponse.ResultModel.BlockchainModel.BlockModel.HeadersModel)
        
        // BlockchainModel.HeaderModel
        case BlockchainHeaderGet(FulcrumResponse.ResultModel.BlockchainModel.HeaderModel.GetModel)
        
        // BlockchainModel.HeadersModel
        case BlockchainHeadersGetTip(FulcrumResponse.ResultModel.BlockchainModel.HeadersModel.GetTipModel)
        case BlockchainHeadersSubscribe(FulcrumResponse.ResultModel.BlockchainModel.HeadersModel.SubscribeModel)
        case BlockchainHeadersUnsubscribe(FulcrumResponse.ResultModel.BlockchainModel.HeadersModel.UnsubscribeModel)
        
        // BlockchainModel.TransactionModel
        case BlockchainTransactionBroadcast(FulcrumResponse.ResultModel.BlockchainModel.TransactionModel.BroadcastModel)
        case BlockchainTransactionGet(FulcrumResponse.ResultModel.BlockchainModel.TransactionModel.GetModel)
        case BlockchainTransactionGetConfirmedBlockHash(FulcrumResponse.ResultModel.BlockchainModel.TransactionModel.GetConfirmedBlockHashModel)
        case BlockchainTransactionGetHeight(FulcrumResponse.ResultModel.BlockchainModel.TransactionModel.GetHeightModel)
        case BlockchainTransactionGetMerkle(FulcrumResponse.ResultModel.BlockchainModel.TransactionModel.GetMerkleModel)
        case BlockchainTransactionIDFromPos(FulcrumResponse.ResultModel.BlockchainModel.TransactionModel.IDFromPosModel)
        case BlockchainTransactionSubscribe(FulcrumResponse.ResultModel.BlockchainModel.TransactionModel.SubscribeModel)
        case BlockchainTransactionUnsubscribe(FulcrumResponse.ResultModel.BlockchainModel.TransactionModel.UnsubscribeModel)
        
        // BlockchainModel.TransactionModel.DSProofModel
        case BlockchainTransactionDSProofGet(FulcrumResponse.ResultModel.BlockchainModel.TransactionModel.DSProofModel.GetModel)
        case BlockchainTransactionDSProofList(FulcrumResponse.ResultModel.BlockchainModel.TransactionModel.DSProofModel.ListModel)
        case BlockchainTransactionDSProofSubscribe(FulcrumResponse.ResultModel.BlockchainModel.TransactionModel.DSProofModel.SubscribeModel)
        case BlockchainTransactionDSProofUnsubscribe(FulcrumResponse.ResultModel.BlockchainModel.TransactionModel.DSProofModel.UnsubscribeModel)
        
        // BlockchainModel.UTXOModel
        case BlockchainUTXOGet(FulcrumResponse.ResultModel.BlockchainModel.UTXOModel.GetInfoModel)
        
        // MempoolModel
        case MempoolGetFeeHistogram(FulcrumResponse.ResultModel.MempoolModel.GetFeeHistogramModel)
    }
}

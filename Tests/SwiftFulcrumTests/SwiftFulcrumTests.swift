import XCTest
@testable import SwiftFulcrum

import Foundation
import Combine

final class SwiftFulcrumTests: XCTestCase {
    let sampleAddress = "qzejakcu3hr2sg392ymj5c7096w3fn0s5gytj88sxl"
    let sampleTransactionID = "fdfc8a39e9fd6bcb9046f6f41c6f99d1f94e25fdcb62b51d8ea2ef6a532b8ad4"
    let sampleBlockHash = "000000000000000000245fa126389ef183fa373120256aca46223c1027a597ce"
    let sampleBlockHeight = UInt(845568)
    let sampleRawTransaction = "01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff0704ffff001d0104ffffffff0100f2052a0100000043410496b538e853519c726a2c91e61ec11600ae1390813a627c66fb8be7947be63c52da7589379515d4e0a604f8141781e62294721166bf621e73a82cbf2342c858eeac00000000"
    
    // MARK: Blockchain
    
    func testGetEstimateFee() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        await fulcrum.submitRequest(.blockchain(.estimateFee(6)), resultType: Response.Result.Blockchain.EstimateFee.self) { result in
            switch result {
            case .success(let estimateFeeResponse):
                XCTAssertGreaterThan(estimateFeeResponse.fee, 0, "Fee should be greater than zero.")
                print("Estimate fee: \(estimateFeeResponse.fee)")
            case .failure(let error):
                XCTFail("Estimate fee failed: \(error.localizedDescription)")
            }
        }
    }
    
    func testGetRelayFee() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        await fulcrum.submitRequest(.blockchain(.relayFee), resultType: Response.Result.Blockchain.RelayFee.self) { result in
            switch result {
            case .success(let relayFeeResponse):
                XCTAssertGreaterThan(relayFeeResponse.fee, 0, "Fee should be greater than zero.")
                print("Relay fee: \(relayFeeResponse.fee)")
            case .failure(let error):
                XCTFail("Relay fee failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: Blockchain.Address
    
    func testGetAddressBalance() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        await fulcrum.submitRequest(.blockchain(.address(.getBalance(sampleAddress, nil))), resultType: Response.Result.Blockchain.Address.GetBalance.self) { result in
            switch result {
            case .success(let getBalanceResponse):
                XCTAssertGreaterThanOrEqual(getBalanceResponse.confirmed, 0, "Confirmed balance should be non-negative.")
                XCTAssertGreaterThanOrEqual(getBalanceResponse.unconfirmed, 0, "Unconfirmed balance should be non-negative.")
                print("Address balance: \(getBalanceResponse)")
            case .failure(let error):
                XCTFail("Get address balance failed: \(error.localizedDescription)")
            }
        }
    }
    
    func testGetAddressFirstUse() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        await fulcrum.submitRequest(.blockchain(.address(.getFirstUse(sampleAddress))), resultType: Response.Result.Blockchain.Address.GetFirstUse.self) { result in
            switch result {
            case .success(let getFirstUseResponse):
                XCTAssertGreaterThan(getFirstUseResponse.height, 0, "Height should be greater than zero.")
                print("Address first use height: \(getFirstUseResponse.height)")
            case .failure(let error):
                XCTFail("Get address first use failed: \(error.localizedDescription)")
            }
        }
    }
    
    func testGetAddressHistory() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        await fulcrum.submitRequest(.blockchain(.address(.getHistory(sampleAddress, nil, nil, true))), resultType: Response.Result.Blockchain.Address.GetHistory.self) { result in
            switch result {
            case .success(let getHistoryResponse):
                XCTAssertFalse(getHistoryResponse.transactions.isEmpty, "Transactions should not be empty.")
                print("Address history count: \(getHistoryResponse.transactions.count)")
            case .failure(let error):
                XCTFail("Get address history failed: \(error.localizedDescription)")
            }
        }
    }
    
    func testGetAddressMempool() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        await fulcrum.submitRequest(.blockchain(.address(.getMempool(sampleAddress))), resultType: Response.Result.Blockchain.Address.GetMempool.self) { result in
            switch result {
            case .success(let getMempoolResponse):
                XCTAssertFalse(getMempoolResponse.transactions.isEmpty, "Transactions should not be empty.")
                print("Address mempool count: \(getMempoolResponse.transactions.count)")
            case .failure(let error):
                XCTFail("Get address mempool failed: \(error.localizedDescription)")
            }
        }
    }
    
    func testGetAddressScriptHash() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        await fulcrum.submitRequest(.blockchain(.address(.getScriptHash(sampleAddress))), resultType: Response.Result.Blockchain.Address.GetScriptHash.self) { result in
            switch result {
            case .success(let getScriptHashResponse):
                XCTAssertFalse(getScriptHashResponse.hash.isEmpty, "Script hash should not be empty.")
                print("Address script hash: \(getScriptHashResponse.hash)")
            case .failure(let error):
                XCTFail("Get address script hash failed: \(error.localizedDescription)")
            }
        }
    }
    
    
    func testListAddressUnspent() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        await fulcrum.submitRequest(.blockchain(.address(.listUnspent(sampleAddress, nil))), resultType: Response.Result.Blockchain.Address.ListUnspent.self) { result in
            switch result {
            case .success(let listUnspentResponse):
                XCTAssertGreaterThanOrEqual(listUnspentResponse.items.count, 0, "The number of UTXO should be greater or equal than zero.")
                print("Address unspent count: \(listUnspentResponse.items.count)")
            case .failure(let error):
                XCTFail("List address unspent failed: \(error.localizedDescription)")
            }
        }
    }
    
    func testAddressSubscription() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        let expectation = XCTestExpectation(description: "Address subscription")
        await fulcrum.submitSubscription(
            .blockchain(.address(.subscribe(sampleAddress))),
            notificationType: Response.Result.Blockchain.Address.SubscribeNotification.self
        ) { result in
            switch result {
            case .success(let subscribeNotification):
                XCTAssertNotNil(subscribeNotification.subscriptionIdentifier, "Subscription identifier should not be nil.")
                print(subscribeNotification)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Address subscription failed: \(error.localizedDescription)")
            }
        }
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testAddressUnsubscription() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        await fulcrum.submitRequest(.blockchain(.address(.unsubscribe(sampleAddress))), resultType: Response.Result.Blockchain.Address.Unsubscribe.self) { result in
            switch result {
            case .success(let unsubscribeResponse):
                XCTAssertTrue(unsubscribeResponse.success, "Unsubscription should be successful.")
                print("Address unsubscribed: \(unsubscribeResponse.success)")
            case .failure(let error):
                XCTFail("Address unsubscription failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: Blockchain.Block
    
    func testGetBlockHeader() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        await fulcrum.submitRequest(.blockchain(.block(.header(sampleBlockHeight, 1))), resultType: Response.Result.Blockchain.Block.Header.self) { result in
            switch result {
            case .success(let blockHeaderResponse):
                XCTAssertFalse(blockHeaderResponse.header.isEmpty, "Header should not be empty.")
                print("Block header: \(blockHeaderResponse.header)")
            case .failure(let error):
                XCTFail("Get block header failed: \(error.localizedDescription)")
            }
        }
    }
    
    func testGetBlockHeaders() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        await fulcrum.submitRequest(.blockchain(.block(.headers(sampleBlockHeight, 10, 0))), resultType: Response.Result.Blockchain.Block.Headers.self) { result in
            switch result {
            case .success(let blockHeadersResponse):
                XCTAssertGreaterThanOrEqual(blockHeadersResponse.count, 0, "Count should be greater than zero.")
                print("Block headers count: \(blockHeadersResponse.count)")
            case .failure(let error):
                XCTFail("Get block headers failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: Blockchain.Header
    
    func testGetHeader() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        await fulcrum.submitRequest(.blockchain(.header(.get(sampleBlockHash))), resultType: Response.Result.Blockchain.Header.Get.self) { result in
            switch result {
            case .success(let headerResponse):
                XCTAssertFalse(headerResponse.hex.isEmpty, "Hex should not be empty.")
                print("Header hex: \(headerResponse.hex)")
            case .failure(let error):
                XCTFail("Get header failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: Blockchain.Headers
    
    func testGetHeadersTip() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        await fulcrum.submitRequest(.blockchain(.headers(.getTip)), resultType: Response.Result.Blockchain.Headers.GetTip.self) { result in
            switch result {
            case .success(let getTipResponse):
                XCTAssertGreaterThan(getTipResponse.height, 0, "Height should be greater than zero.")
                print("Headers tip height: \(getTipResponse.height)")
            case .failure(let error):
                XCTFail("Get headers tip failed: \(error.localizedDescription)")
            }
        }
    }
    
    func testLastBlockSubscription() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        let expectation = XCTestExpectation(description: "Last block subscription")
        await fulcrum.submitSubscription(
            .blockchain(.headers(.subscribe)),
            notificationType: Response.Result.Blockchain.Headers.SubscribeNotification.self
        ) { result in
            switch result {
            case .success(let subscribeNotification):
                XCTAssertNotNil(subscribeNotification.subscriptionIdentifier, "Subscription identifier should not be nil.")
                
                XCTAssertGreaterThan(subscribeNotification.block.height, 0)
                XCTAssertFalse(subscribeNotification.block.hex.isEmpty)
                
                print("Height: \(subscribeNotification.block.height)")
                print("Hex: \(subscribeNotification.block.hex)")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Last block subscription failed: \(error.localizedDescription)")
            }
        }
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testHeadersUnsubscription() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        await fulcrum.submitRequest(.blockchain(.headers(.unsubscribe)), resultType: Response.Result.Blockchain.Headers.Unsubscribe.self) { result in
            switch result {
            case .success(let unsubscribeResponse):
                XCTAssertTrue(unsubscribeResponse.success, "Unsubscription should be successful.")
                print("Headers unsubscribed: \(unsubscribeResponse.success)")
            case .failure(let error):
                XCTFail("Headers unsubscription failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: Blockchain.Transaction
    
    func testBroadcastTransaction() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        await fulcrum.submitRequest(.blockchain(.transaction(.broadcast(sampleRawTransaction))), resultType: Response.Result.Blockchain.Transaction.Broadcast.self) { result in
            switch result {
            case .success(let broadcastResponse):
                XCTAssertTrue(broadcastResponse.success, "Broadcast should be successful.")
                print("Broadcast success: \(broadcastResponse.success)")
            case .failure(let error):
                XCTFail("Broadcast transaction failed: \(error.localizedDescription)")
            }
        }
    }
    
    func testGetTransaction() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        await fulcrum.submitRequest(.blockchain(.transaction(.get(sampleTransactionID, true))), resultType: Response.Result.Blockchain.Transaction.Get.self) { result in
            switch result {
            case .success(let transactionResponse):
                XCTAssertFalse(transactionResponse.hex.isEmpty, "Transaction hex should not be empty.")
                print("Transaction hex: \(transactionResponse.hex)")
            case .failure(let error):
                XCTFail("Get transaction failed: \(error.localizedDescription)")
            }
        }
    }
    
    func testGetTransactionConfirmedBlockHash() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        await fulcrum.submitRequest(.blockchain(.transaction(.getConfirmedBlockHash(sampleTransactionID, true))), resultType: Response.Result.Blockchain.Transaction.GetConfirmedBlockHash.self) { result in
            switch result {
            case .success(let blockHashResponse):
                XCTAssertFalse(blockHashResponse.blockHash.isEmpty, "Block hash should not be empty.")
                print("Transaction confirmed block hash: \(blockHashResponse.blockHash)")
            case .failure(let error):
                XCTFail("Get transaction confirmed block hash failed: \(error.localizedDescription)")
            }
        }
    }
    
    func testGetTransactionHeight() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        await fulcrum.submitRequest(.blockchain(.transaction(.getHeight(sampleTransactionID))), resultType: Response.Result.Blockchain.Transaction.GetHeight.self) { result in
            switch result {
            case .success(let heightResponse):
                XCTAssertGreaterThan(heightResponse.height, 0, "Height should be greater than zero.")
                print("Transaction height: \(heightResponse.height)")
            case .failure(let error):
                XCTFail("Get transaction height failed: \(error.localizedDescription)")
            }
        }
    }
    
    func testGetTransactionMerkle() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        await fulcrum.submitRequest(.blockchain(.transaction(.getMerkle(sampleTransactionID))), resultType: Response.Result.Blockchain.Transaction.GetMerkle.self) { result in
            switch result {
            case .success(let merkleResponse):
                XCTAssertGreaterThan(merkleResponse.blockHeight, 0, "Block height should be greater than zero.")
                XCTAssertGreaterThan(merkleResponse.position, 0, "Position should be greater than zero.")
                print("Transaction merkle: \(merkleResponse)")
            case .failure(let error):
                XCTFail("Get transaction merkle failed: \(error.localizedDescription)")
            }
        }
    }
    
    func testGetTransactionIDFromPos() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        await fulcrum.submitRequest(.blockchain(.transaction(.idFromPos(sampleBlockHeight, 1, true))), resultType: Response.Result.Blockchain.Transaction.GetMerkle.self) { result in
            switch result {
            case .success(let idFromPosResponse):
                XCTAssertGreaterThan(idFromPosResponse.blockHeight, 0, "Block height should be greater than zero.")
                XCTAssertGreaterThan(idFromPosResponse.position, 0, "Position should be greater than zero.")
                print("ID from pos: \(idFromPosResponse)")
            case .failure(let error):
                XCTFail("Get id from position failed: \(error.localizedDescription)")
            }
        }
    }
    
    func testTransactionSubscription() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        let expectation = XCTestExpectation(description: "Transaction subscription")
        await fulcrum.submitSubscription(
            .blockchain(.transaction(.subscribe(sampleTransactionID))),
            notificationType: Response.Result.Blockchain.Transaction.SubscribeNotification.self
        ) { result in
            switch result {
            case .success(let subscribeNotification):
                XCTAssertNotNil(subscribeNotification.subscriptionIdentifier, "Subscription identifier should not be nil.")
                
                print("Height: \(subscribeNotification.height)")
                print("Hex: \(subscribeNotification.transactionHash)")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Transaction subscription failed: \(error.localizedDescription)")
            }
        }
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testTransactionUnsubscription() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        await fulcrum.submitRequest(.blockchain(.transaction(.unsubscribe(sampleTransactionID))), resultType: Response.Result.Blockchain.Transaction.Unsubscribe.self) { result in
            switch result {
            case .success(let unsubscribeResponse):
                XCTAssertTrue(unsubscribeResponse.success, "Unsubscription should be successful.")
                print("Transaction unsubscribed: \(unsubscribeResponse.success)")
            case .failure(let error):
                XCTFail("Transaction unsubscription failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: Blockchain.Transaction.DSProof
    
    func testGetTransactionDSProof() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        await fulcrum.submitRequest(.blockchain(.transaction(.dsProof(.get(sampleTransactionID)))), resultType: Response.Result.Blockchain.Transaction.DSProof.Get.self) { result in
            switch result {
            case .success(let dsproofResponse):
                XCTAssertFalse(dsproofResponse.dspID.isEmpty, "DS proof should not be empty")
                print("DS proof: \(dsproofResponse)")
            case .failure(let error):
                XCTFail("DS proof failed: \(error.localizedDescription)")
            }
        }
    }
    
    func testListTransactionDSProof() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        await fulcrum.submitRequest(.blockchain(.transaction(.dsProof(.list))), resultType: Response.Result.Blockchain.Transaction.DSProof.List.self) { result in
            switch result {
            case .success(let dsproofListResponse):
                XCTAssertNotNil(dsproofListResponse.transactionHashes, "DS proof list should not be empty.")
                print("DS Proof list: \(dsproofListResponse)")
            case .failure(let error):
                XCTFail("List dsproof failed: \(error.localizedDescription)")
            }
        }
    }
    
    func testTransactionDSProofSubscription() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        let expectation = XCTestExpectation(description: "DS Proof subscription")
        await fulcrum.submitSubscription(
            .blockchain(.transaction(.dsProof(.subscribe(sampleTransactionID)))),
            notificationType: Response.Result.Blockchain.Transaction.DSProof.SubscribeNotification.self
        ) { result in
            switch result {
            case .success(let subscribeNotification):
                XCTAssertNotNil(subscribeNotification.subscriptionIdentifier, "Subscription identifier should not be nil.")
                
                print("Hex: \(subscribeNotification.transactionHash)")
                print("Proof hex: \(subscribeNotification.proof?.hex ?? "nil")")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("DS proof subscription failed: \(error.localizedDescription)")
            }
        }
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testTransactionDSProofUnsubscription() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        await fulcrum.submitRequest(.blockchain(.transaction(.dsProof(.unsubscribe(sampleTransactionID)))), resultType: Response.Result.Blockchain.Transaction.DSProof.Unsubscribe.self) { result in
            switch result {
            case .success(let unsubscribeResponse):
                XCTAssertTrue(unsubscribeResponse.success, "Unsubscription should be successful.")
                print("DS proof unsubscribed: \(unsubscribeResponse.success)")
            case .failure(let error):
                XCTFail("DS proof unsubscription failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: Blockchain.UTXO
    
    func testGetUTXOInfo() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        await fulcrum.submitRequest(.blockchain(.utxo(.getInfo(sampleTransactionID, 1))), resultType: Response.Result.Blockchain.UTXO.GetInfo.self) { result in
            switch result {
            case .success(let utxoInfoResponse):
                XCTAssertGreaterThan(utxoInfoResponse.value, 0, "Value should be greater than zero.")
                XCTAssertFalse(utxoInfoResponse.scriptHash.isEmpty, "Script hash should not be empty.")
                print("UTXO info: \(utxoInfoResponse)")
            case .failure(let error):
                XCTFail("Get UTXO Info failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: Mempool
    func testGetFeeHistogram() async throws {
        var fulcrum = try XCTUnwrap(SwiftFulcrum())
        await fulcrum.submitRequest(.mempool(.getFeeHistogram), resultType: Response.Result.Mempool.GetFeeHistogram.self) { result in
            switch result {
            case .success(let feeHistogramResponse):
                XCTAssertGreaterThan(feeHistogramResponse.histogram.count, 0, "Histogram should not be empty.")
                print("Fee histogram: \(feeHistogramResponse.histogram)")
            case .failure(let error):
                XCTFail("Get Fee histogram failed: \(error.localizedDescription)")
            }
        }
    }
}

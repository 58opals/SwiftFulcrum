import Testing
import Foundation
@testable import SwiftFulcrum

@Suite("Fulcrum Tests")
struct FulcrumTests {
    let fulcrum: Fulcrum
    
    init() async throws {
        self.fulcrum = try .init()
        
        try await self.fulcrum.start()
    }
}

extension FulcrumTests {
    @Test func testSubmitRequestSuccess() async throws {
        let (id, result) = try await fulcrum.submit(method:
                .blockchain(.relayFee),
                                 responseType:
                                    Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.RelayFee>.self
        )
        
        print(id.uuidString)
        print(result)
    }
}


//import XCTest
//@testable import SwiftFulcrum
//
//import Combine
//
//final class FulcrumTests: XCTestCase {
//    var fulcrum: Fulcrum!
//    
//    override func setUp() {
//        super.setUp()
//        fulcrum = try! Fulcrum()
//    }
//    
//    override func tearDown() {
//        fulcrum = nil
//        super.tearDown()
//    }
//}
//
//extension FulcrumTests {
//    func testSubmitRequestSuccess() async throws {
//        let expectation = self.expectation(description: "Request should succeed")
//        
//        let (id, publisher) = try await fulcrum.submit(
//            method: .blockchain(.transaction(.broadcast(rawTransaction: "rawtx"))),
//            responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.Broadcast>.self
//        )
//        let subscription = publisher
//            .sink(
//                receiveCompletion: { completion in
//                    switch completion {
//                    case .finished:
//                        print("\(id) finished.")
//                    case .failure(let error):
//                        XCTFail("Request failed with error: \(error.localizedDescription)")
//                    }
//                },
//                receiveValue: { transactionHash in
//                    print("Hello, value!: \(transactionHash)")
//                    expectation.fulfill()
//                }
//            )
//        
//        fulcrum.subscriptionHub.add(subscription, for: id)
//        
//        await fulfillment(of: [expectation], timeout: 10.0)
//    }
//    
//    func testSubmitAddressSubscriptionSuccess() async throws {
//        let expectation = self.expectation(description: "Subscription should receive notifications")
//        
//        let address = "qpfsvdn6lra722s5m3s82wkccpdrc6wutu8k096jj4"
//        
//        let (id, publisher) = try await fulcrum.submit(
//            method: .blockchain(.address(.subscribe(address: address))),
//            notificationType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.Subscribe>.self)
//        let subscription = publisher
//            .sink(
//                receiveCompletion: { completion in
//                    switch completion {
//                    case .finished:
//                        print("\(id) finished.")
//                    case .failure(let error):
//                        XCTFail("Subscription failed with error: \(error.localizedDescription)")
//                    }
//                },
//                receiveValue: { notification in
//                    guard let notification = notification else { return }
//                    switch notification {
//                    case .status(let status):
//                        print(status)
//                    case .addressAndStatus(let addressAndStatus):
//                        print(addressAndStatus)
//                        expectation.fulfill()
//                    }
//                }
//            )
//        
//        fulcrum.subscriptionHub.add(subscription, for: id)
//        
//        await fulfillment(of: [expectation], timeout: (1.0 * 60) * 15)
//    }
//    
//    func testSubmitHeadersSubscriptionSuccess() async throws {
//        let expectation = self.expectation(description: "Subscription should receive notifications")
//        
//        let (id, publisher) = try await fulcrum.submit(
//            method: .blockchain(.headers(.subscribe)),
//            notificationType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Headers.Subscribe>.self)
//        let subscription = publisher
//            .sink(
//                receiveCompletion: { completion in
//                    switch completion {
//                    case .finished:
//                        print("\(id) finished.")
//                    case .failure(let error):
//                        XCTFail("Subscription failed with error: \(error.localizedDescription)")
//                    }
//                },
//                receiveValue: { notification in
//                    guard let notification = notification else { return }
//                    switch notification {
//                    case .topHeader(let header):
//                        print(header)
//                    case .newHeader(let header):
//                        print(header)
//                        expectation.fulfill()
//                    }
//                }
//            )
//        
//        fulcrum.subscriptionHub.add(subscription, for: id)
//        
//        await fulfillment(of: [expectation], timeout: (1.0 * 60) * 15)
//    }
//    
//    func testSubmitTransactionSubscriptionSuccess() async throws {
//        let expectation = self.expectation(description: "Subscription should receive notifications")
//        
//        let transactionHash = "58d40d5404c36794d6d4787bd57c52d5d32b74dc223b934e43fbff991d2d8e62"
//        
//        let (id, publisher) = try await fulcrum.submit(
//            method: .blockchain(.transaction(.subscribe(transactionHash: transactionHash))),
//            notificationType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.Subscribe>.self)
//        let subscription = publisher
//            .sink(
//                receiveCompletion: { completion in
//                    switch completion {
//                    case .finished:
//                        print("\(id) finished.")
//                    case .failure(let error):
//                        XCTFail("Subscription failed with error: \(error.localizedDescription)")
//                    }
//                },
//                receiveValue: { notification in
//                    guard let notification = notification else { return }
//                    switch notification {
//                    case .height(let height):
//                        print(height)
//                    case .transactionHashAndHeight(let transactionHashAndHeight):
//                        print(transactionHashAndHeight)
//                        expectation.fulfill()
//                    }
//                }
//            )
//        
//        fulcrum.subscriptionHub.add(subscription, for: id)
//        
//        await fulfillment(of: [expectation], timeout: (1.0 * 60) * 15)
//    }
//    
//    func testSubmitTransactionDSProofSubscriptionSuccess() async throws {
//        let expectation = self.expectation(description: "Subscription should receive notifications")
//        
//        let transactionHash = "77bca070d923c73fbc2819531e29669db8f51da0aee4aa2fd62b534789cbc375"
//        
//        let (id, publisher) = try await fulcrum.submit(
//            method: .blockchain(.transaction(.dsProof(.subscribe(transactionHash: transactionHash)))),
//            notificationType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Transaction.DSProof.Subscribe>.self)
//        let subscription = publisher
//            .sink(
//                receiveCompletion: { completion in
//                    switch completion {
//                    case .finished:
//                        print("\(id) finished.")
//                    case .failure(let error):
//                        XCTFail("Subscription failed with error: \(error.localizedDescription)")
//                    }
//                },
//                receiveValue: { notification in
//                    guard let notification = notification else { return }
//                    switch notification {
//                    case .dsProof(let dsProof):
//                        print(dsProof ?? "empty!")
//                    case .transactionHashAndDSProof(let transactionHashAndDSProof):
//                        print(transactionHashAndDSProof)
//                        expectation.fulfill()
//                    }
//                }
//            )
//        
//        fulcrum.subscriptionHub.add(subscription, for: id)
//        
//        await fulfillment(of: [expectation], timeout: (1.0 * 60) * 15)
//    }
//}

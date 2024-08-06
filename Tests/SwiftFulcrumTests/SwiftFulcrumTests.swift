import XCTest
@testable import SwiftFulcrum

import Combine

final class SwiftFulcrumTests: XCTestCase {
    var fulcrum: SwiftFulcrum!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        fulcrum = try! SwiftFulcrum()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        fulcrum = nil
        cancellables = nil
        super.tearDown()
    }
}

extension SwiftFulcrumTests {
    func testSubmitRequestSuccess() async throws {
        let expectation = self.expectation(description: "Request should succeed")
        
        let (id, publisher) = try await fulcrum.submit(method: .blockchain(.estimateFee(numberOfBlocks: 6)),
                                                       responseType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.EstimateFee>.self)
        publisher
        .sink(
            receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("\(id) finished.")
                case .failure(let error):
                    XCTFail("Request failed with error: \(error.localizedDescription)")
                }
            },
            receiveValue: { estimateFee in
                //print("Hello, value!: \(estimateFee)")
                XCTAssertEqual(estimateFee, 0.00001)
                expectation.fulfill()
            })
        .store(in: &cancellables)
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    func testSubmitSubscriptionSuccess() async throws {
        let expectation = self.expectation(description: "Subscription should receive notifications")
        
        let address = "qrsrz5mzve6kyr6ne6lgsvlgxvs3hqm6huxhd8gqwj"
        
        let (id, publisher) = try await fulcrum.submit(method: .blockchain(.address(.subscribe(address: address))),
                                                       resultType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.Subscribe>.self,
                                                       notificationType: Response.JSONRPC.Generic<Response.JSONRPC.Result.Blockchain.Address.SubscribeNotification>.self)
        publisher
        .sink(
            receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("\(id) finished.")
                case .failure(let error):
                    XCTFail("Subscription failed with error: \(error.localizedDescription)")
                }
            },
            receiveValue: { notification in
                print(notification)
                XCTAssertEqual(notification.address, address)
                expectation.fulfill()
            })
        .store(in: &cancellables)
        
        await fulfillment(of: [expectation], timeout: (1.0 * 60) * 15)
    }
}

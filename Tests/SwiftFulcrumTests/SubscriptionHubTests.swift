import XCTest
@testable import SwiftFulcrum

import Combine

final class SubscriptionHubTests: XCTestCase {
    var subscriptionHub: SubscriptionHub!
    
    override func setUp() {
        super.setUp()
        subscriptionHub = SubscriptionHub()
    }
    
    override func tearDown() {
        subscriptionHub.cancelAll()
        subscriptionHub = nil
        super.tearDown()
    }
    
    func testAddAndCancelSingleSubscription() {
        let expectation = XCTestExpectation(description: "Subscription receives value")
        let subject = PassthroughSubject<String, Never>()
        let uuid = UUID()
        
        let subscription = subject.sink(receiveValue: { value in
            XCTAssertEqual(value, "test")
            expectation.fulfill()
        })
        
        subscriptionHub.add(subscription, for: uuid)
        subject.send("test")
        
        subscriptionHub.cancel(for: uuid)
        subject.send("should not be received")
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCancelAllSubscriptions() {
        let expectation1 = XCTestExpectation(description: "First subscription receives value")
        let expectation2 = XCTestExpectation(description: "Second subscription receives value")
        
        let subject1 = PassthroughSubject<String, Never>()
        let theInitialValueForCurrentValueSubject = "initial"
        let subject2 = CurrentValueSubject<String, Never>(theInitialValueForCurrentValueSubject)
        
        let uuid1 = UUID()
        let uuid2 = UUID()
        
        let subscription1 = subject1.sink(receiveValue: { value in
            XCTAssertEqual(value, "test1")
            expectation1.fulfill()
        })
        
        let subscription2 = subject2.sink(receiveValue: { value in
            guard value != theInitialValueForCurrentValueSubject else { return }
            XCTAssertEqual(value, "test2")
            expectation2.fulfill()
        })
        
        subscriptionHub.add(subscription1, for: uuid1)
        subscriptionHub.add(subscription2, for: uuid2)
        
        subject1.send("test1")
        subject2.send("test2")
        
        subscriptionHub.cancelAll()
        subject1.send("should not be received")
        subject2.send("should not be received")
        
        wait(for: [expectation1, expectation2], timeout: 1.0)
    }
    
    func testAddAndCancelMultipleSubscriptions() {
        let expectation1 = XCTestExpectation(description: "First subscription receives value")
        let expectation2 = XCTestExpectation(description: "Second subscription receives value")
        let expectation3 = XCTestExpectation(description: "Third subscription receives value")
        let subject1 = PassthroughSubject<String, Never>()
        let theInitialValueForCurrentValueSubject = "initial"
        let subject2 = CurrentValueSubject<String, Never>(theInitialValueForCurrentValueSubject)
        let subject3 = PassthroughSubject<Int, Never>()
        
        let uuid1 = UUID()
        let uuid2 = UUID()
        let uuid3 = UUID()
        
        let subscription1 = subject1.sink(receiveValue: { value in
            XCTAssertEqual(value, "test1")
            expectation1.fulfill()
        })
        
        let subscription2 = subject2.sink(receiveValue: { value in
            guard value != theInitialValueForCurrentValueSubject else { return }
            XCTAssertEqual(value, "test2")
            expectation2.fulfill()
        })
        
        let subscription3 = subject3.sink(receiveValue: { value in
            XCTAssertEqual(value, 123)
            expectation3.fulfill()
        })
        
        subscriptionHub.add(subscription1, for: uuid1)
        subscriptionHub.add(subscription2, for: uuid2)
        subscriptionHub.add(subscription3, for: uuid3)
        
        subject1.send("test1")
        subject2.send("test2")
        subject3.send(123)
        
        subscriptionHub.cancel(for: uuid1)
        subscriptionHub.cancel(for: uuid2)
        subscriptionHub.cancel(for: uuid3)
        
        subject1.send("should not be received")
        subject2.send("should not be received")
        subject3.send(456)
        
        wait(for: [expectation1, expectation2, expectation3], timeout: 1.0)
    }
}

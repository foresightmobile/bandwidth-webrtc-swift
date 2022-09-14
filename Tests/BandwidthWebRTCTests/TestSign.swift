//
//  TestSign.swift
//  
//
//  Created by user on 14.09.2022.
//

import XCTest
@testable import JSONRPCWebSockets
@testable import BandwidthWebRTC


class TestSign: XCTestCase {

    var fakeClient: FakeClient!
    var sut: SignalingImpl!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        fakeClient = FakeClient()
        sut = SignalingImpl(client: fakeClient)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        fakeClient = nil
        sut = nil
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        // Arrange
        let expectation = self.expectation(description: "Signup Web Service Response Expectation")
//        expectation.expectedFulfillmentCount = 2
        expectation.assertForOverFulfill = false

        // Act
        let endpoint = BandwidthEndpoint.using(token: UUID().uuidString, sdkVersion: UUID().uuidString)
        fakeClient.shouldSubscribeMethodReturnError = true
        fakeClient.shouldCallMethodReturnError = true
        
        sut.connect(to: endpoint.url!) { result in
            print("res:", result)
            switch result {
            case .success():
                print("succ:")
//                XCTAssertEqual(self.fakeClient.isSubscribeMethodCalled, true, "subscribe Method must be called")
//                XCTAssertEqual(self.fakeClient.isOnMethodCalled, true, "subscribe Method must be called")
//                XCTAssertEqual(self.fakeClient.isConnectMethodCalled, true, "subscribe Method must be called")
//            case .failure(let err):
                print("hz err:")
                XCTAssertNotNil(err)
//                XCTAssertEqual(ClientError.duplicateSubscription.localizedDescription, err.localizedDescription)
                XCTAssertEqual(self.fakeClient.isSubscribeMethodCalled, true)
            }
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 5)
    }
    
    
    func testExample2() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        // Arrange
        let expectation = self.expectation(description: "Signup Expectation")
        
        // Act
        let endpoint = BandwidthEndpoint.using(token: UUID().uuidString, sdkVersion: UUID().uuidString)
        fakeClient.shouldSubscribeMethodReturnError = false
        
        sut.connect(to: endpoint.url!) { result in
            switch result {
            case .success():
                print("succ:")
                XCTAssertEqual(self.fakeClient.isSubscribeMethodCalled, true, "subscribe Method must be called")
                XCTAssertEqual(self.fakeClient.isOnMethodCalled, true, "subscribe Method must be called")
                XCTAssertEqual(self.fakeClient.isConnectMethodCalled, true, "subscribe Method must be called")

            case .failure(let err):
                print("err:")
                print(err.localizedDescription)
                XCTAssertEqual(self.fakeClient.isSubscribeMethodCalled, true)
            }
            expectation.fulfill()
        }
        self.wait(for: [expectation], timeout: 5)
    }
}







class FakeClient: ClientProvider {
 
//    var isSignupMethodCalled: Bool = false
//    var shouldReturnError: Bool = false
    
    var isSubscribeMethodCalled: Bool = false
    var shouldSubscribeMethodReturnError: Bool = false
    
    var isOnMethodCalled: Bool = false
    var isConnectMethodCalled: Bool = false
    
    var isCallMethodCalled: Bool = false
    var shouldCallMethodReturnError: Bool = false

    func connect(url: URL, queue: OperationQueue?, completion: @escaping () -> Void) {
        print("connect:")
        self.isConnectMethodCalled = true
        completion()
    }
    func disconnect(completion: @escaping () -> Void){}
    func notify<T: Codable>(method: String, parameters: T, completion: @escaping (Result<(), Error>) -> Void){}
    func call<T: Codable, U: Decodable>(method: String, parameters: T, type: U.Type, timeout: TimeInterval?, completion: @escaping (Result<U?, Error>) -> Void){
        self.isCallMethodCalled = true
        
        if shouldCallMethodReturnError {
            completion(.failure(ClientError.invalid(data: Data(), encoding: .utf8)))
        }else {
            completion(.success(nil))
        }
    }
//    func subscribe<T: Codable>(to method: String, type: T.Type) throws{}
    func on<T: Codable>(method: String, type: T.Type, completion: @escaping (T) -> Void) {
        print("on:")
        self.isOnMethodCalled = true
        completion(SDPOfferParams(endpointId: "", sdpOffer: "", sdpRevision: 0, streamMetadata: [:]) as! T)
    }
    func unsubscribe(from method: String){}
    
    
    func subscribe<T: Codable>(to method: String, type: T.Type) throws {
        print("subscribe:")
        isSubscribeMethodCalled = true
        
        if shouldSubscribeMethodReturnError {
            print("throw eer")
            throw ClientError.duplicateSubscription
        }
    }
}

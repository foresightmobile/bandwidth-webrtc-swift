//
//  TestSign.swift
//  
//
//  Created by user on 14.09.2022.
//

import XCTest
@testable import JSONRPCWebSockets
@testable import BandwidthWebRTC

class SignalingTests: XCTestCase {
    private var delegateMock: SignalingDelegateMock!
    private var fakeClient: FakeClient!
    private var sut: SignalingImpl!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        fakeClient = FakeClient()
        sut = SignalingImpl(client: fakeClient)
        delegateMock = SignalingDelegateMock()
        sut.delegate = delegateMock
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        delegateMock = nil
        fakeClient = nil
        sut = nil
    }
    
    func testSignalingDelegate() throws {
        let expectation = self.expectation(description: #function)
        var capturedResult: Result<(), Error>?
        
        let endpoint = BandwidthEndpoint.using(token: UUID().uuidString, sdkVersion: UUID().uuidString)
        let SDPOfferParamsStub = SDPOfferParams(endpointId: "1", sdpOffer: "", sdpRevision: 00, streamMetadata: [:])
        delegateMock.shouldReturnStubData = .some(SDPOfferParamsStub)
        let stubMedia = SetMediaPreferencesParameters(protocol: "protocol")
        fakeClient.returnStubInput = .value(.some(stubMedia))
        
        sut.connect(to: endpoint.url!) { result in
            capturedResult = result
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            guard case .success() = capturedResult else {
                return XCTFail("Expected to be a success but got a failure with \(String(describing: capturedResult))")
            }
            XCTAssertEqual(self.delegateMock.invokedMethod, .didRecieveOfferSDP(parameters: SDPOfferParamsStub), "Signaling delegate invoke method should be the same")
        }
    }
    
    func testAnswerSdp_shouldReturnStubError() throws {
        let expectation = self.expectation(description: #function)
        var capturedResult: Result<AnswerSDPResult?, Error>?
        
        let stubSDP = "sdp-123"
        let stubError = ClientError.duplicateSubscription
        
        fakeClient.returnStubInput = .err(.some(stubError))
        
        sut.answer(sdp: stubSDP) { result in
            capturedResult = result
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(self.fakeClient.isCallMethodCalled, true,  "call: method must be called")
            
            switch capturedResult {
            case .success(_):
                XCTFail("Expected to be a failure case")
            case .failure(let err):
                XCTAssertEqual(stubError.localizedDescription, err.localizedDescription)
            case .none:
                XCTFail("Expected to be a failure case")
            }
        }
    }
    
    func testAnswerSdp_shouldReturnStubValue() throws {
        let expectation = self.expectation(description: #function)
        var capturedResult: Result<AnswerSDPResult?, Error>?
        
        let stubSDP = "sdp-123"
        let answerSDPResultStub = AnswerSDPResult()
        
        fakeClient.returnStubInput = .value(.some(answerSDPResultStub))
        
        sut.answer(sdp: stubSDP) { result in
            capturedResult = result
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(self.fakeClient.isCallMethodCalled, true, "call: method must be called")
            
            switch capturedResult {
            case .success(let answer):
                XCTAssertEqual(answer, answerSDPResultStub)
            case .failure(let err):
                XCTFail("Expected to be a success but got a failure with \(err.localizedDescription)")
            case .none:
                XCTFail("Expected to be a success")
            }
        }
    }
    
    func testConnectMethod_shouldFail() throws {
        let expectation = self.expectation(description: #function)
        expectation.assertForOverFulfill = false
        var capturedResult: Result<(), Error>?
        
        let endpoint = BandwidthEndpoint.using(token: UUID().uuidString, sdkVersion: UUID().uuidString)
        
        let stubError = ClientError.duplicateSubscription
        fakeClient.shouldSubscribeMethodReturnError = .some(stubError)
        
        sut.connect(to: endpoint.url!) { result in
            capturedResult = result
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            switch capturedResult {
            case .success():
                XCTFail("Expected to be a failure case")
            case .failure(let err):
                XCTAssertEqual(self.fakeClient.isSubscribeMethodCalled, true, "call: method must be called")
                XCTAssertEqual(stubError.localizedDescription, err.localizedDescription)
            case .none:
                XCTFail("Expected to be a failure case")
            }
        }
    }
    
    func testConnectMethod_shouldSuccess() throws {
        let expectation = self.expectation(description: #function)
        //        expectation.expectedFulfillmentCount = 2
        expectation.assertForOverFulfill = false
        
        var capturedResult: Result<(), Error>?
        
        let stubEndpoint = BandwidthEndpoint.using(token: UUID().uuidString, sdkVersion: UUID().uuidString)
        let stubMedia = SetMediaPreferencesParameters(protocol: "protocol")
        fakeClient.returnStubInput = .value(.some(stubMedia))
        
        sut.connect(to: stubEndpoint.url!) { result in
            capturedResult = result
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            switch capturedResult {
            case .success():
                XCTAssertEqual(self.fakeClient.isSubscribeMethodCalled, true, "subscribe: Method must be called")
                XCTAssertEqual(self.fakeClient.isOnMethodCalled, true, "on: Method must be called")
                XCTAssertEqual(self.fakeClient.isConnectMethodCalled, true, "connect: Method must be called")
            case .failure(let err):
                XCTFail("Expected to be a success but got a failure with \(err.localizedDescription)")
            case .none:
                XCTFail("Expected to be a success case")
            }
        }
    }

    func testOffer_shouldReturnStubError() throws {
        let expectation = self.expectation(description: #function)
        var capturedResult: Result<OfferSDPResult?, Error>?
        
        let stubSDP = "sdp-123"
        let stubMeta = PublishMetadata(mediaStreams: [:], dataChannels: [:])
        let stubError = ClientError.duplicateSubscription
        fakeClient.shouldSubscribeMethodReturnError = .some(stubError)

        sut.offer(sdp: stubSDP, publishMetadata: stubMeta) { result in
            capturedResult = result
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(self.fakeClient.isCallMethodCalled, true,  "call: method must be called")
            
            switch capturedResult {
            case .success(_):
                XCTFail("Expected to be a failure case")
            case .failure(let err):
                XCTAssertEqual(stubError.localizedDescription, err.localizedDescription)
            case .none:
                XCTFail("Expected to be a failure case")
            }
        }
    }
    
    func testOffer_shouldReturnStubValue() throws {
        let expectation = self.expectation(description: #function)
        var capturedResult: Result<OfferSDPResult?, Error>?
        
        let stubSDP = "sdp-123"
        let stubMeta = PublishMetadata(mediaStreams: [:], dataChannels: [:])
        let offerSDPResultStub = OfferSDPResult(endpointId: "", sdpAnswer: "", streamMetadata: [:])
        fakeClient.returnStubInput = .value(.some(offerSDPResultStub))

        sut.offer(sdp: stubSDP, publishMetadata: stubMeta) { result in
            capturedResult = result
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(self.fakeClient.isCallMethodCalled, true, "call: method must be called")
            
            switch capturedResult {
            case .success(let answer):
                XCTAssertEqual(answer, offerSDPResultStub)
            case .failure(let err):
                XCTFail("Expected to be a success but got a failure with \(err.localizedDescription)")
            case .none:
                XCTFail("Expected to be a success")
            }
        }
    }
    
    func testDisconnect() throws {
        sut.disconnect()
        XCTAssertEqual(fakeClient.isNotifyMethodCalled, true)
        XCTAssertEqual(fakeClient.isDisconnectMethodCalled, true)
    }
    
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        // Arrange
    }
}

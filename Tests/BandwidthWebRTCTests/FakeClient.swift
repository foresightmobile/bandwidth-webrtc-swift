//
//  FakeClient.swift
//  
//
//  Created by user on 18.09.2022.
//

import Foundation
@testable import BandwidthWebRTC
@testable import JSONRPCWebSockets

final class FakeClient: ClientProvider {
    enum DelegateMethod: Equatable {
        case connect
        case disconnect
        case notify
        case call
        case subscribe
        case on
        case unsubscribe
    }
    
    // MARK: - Public properties
    private(set) var invokedMethods = [DelegateMethod]()
    
    
    //MARK: - Connect: Method
    var isConnectMethodCalled: Bool {
        invokedMethods.contains(.connect)
    }
    func connect(url: URL, queue: OperationQueue?, completion: @escaping () -> Void) {
        invokedMethods.append(.connect)
        completion()
    }
    
    
    //MARK: - Disconnect: Method
    var isDisconnectMethodCalled: Bool {
        invokedMethods.contains(.disconnect)
    }
    func disconnect(completion: @escaping () -> Void) {
        invokedMethods.append(.disconnect)
        completion()
    }
    
    
    //MARK: - Notify: Method
    var isNotifyMethodCalled: Bool {
        invokedMethods.contains(.notify)
    }
    func notify<T>(method: String, parameters: T, completion: @escaping (Result<(), Error>) -> Void) where T : Decodable, T : Encodable {
        invokedMethods.append(.notify)
        
    }
    
    
    //MARK: - Call: Method
    var returnStubInput: StubResult = .err(.none)
    var isCallMethodCalled: Bool {
        invokedMethods.contains(.call)
    }
    
    func call<T, U>(method: String, parameters: T, type: U.Type, timeout: TimeInterval?, completion: @escaping (Result<U?, Error>) -> Void) where T : Decodable, T : Encodable, U : Decodable {
        
        invokedMethods.append(.call)
        
        switch returnStubInput {
        case .err(let state):
            switch state {
            case .none:
                completion(.failure(ClientError.duplicateSubscription))
            case .some(let err):
                completion(.failure(err))
            }
        case .value(let state):
            switch state {
            case .none:
                completion(.success(nil))
            case .some(let stub):
                completion(.success(stub as? U))
            }
        }
    }
    
    
    //MARK: - Subscribe: Method
    var shouldSubscribeMethodReturnError: StubState<Error> = .none
    var isSubscribeMethodCalled: Bool {
        invokedMethods.contains(.subscribe)
    }
    func subscribe<T>(to method: String, type: T.Type) throws where T : Decodable, T : Encodable {
        invokedMethods.append(.subscribe)
        
        switch shouldSubscribeMethodReturnError {
        case .none: break
        case .some(let stubError):
            throw stubError
        }
    }
    
    
    //MARK: - On: Method
    var shouldonMethodReturnStub: StubState<SDPOfferParams> = .none
    var isOnMethodCalled: Bool {
        invokedMethods.contains(.on)
    }
    
    func on<T>(method: String, type: T.Type, completion: @escaping (T) -> Void) where T : Decodable, T : Encodable {
        invokedMethods.append(.on)
        switch shouldonMethodReturnStub {
        case .none:
            completion(SDPOfferParams(endpointId: "", sdpOffer: "", sdpRevision: 0, streamMetadata: [:]) as! T)
        case .some(let stub):
            completion(stub as! T)
        }
    }
    
    
    //MARK: - Notify: Method
    var isUnsubscribeMethodCalled: Bool {
        invokedMethods.contains(.unsubscribe)
    }
    func unsubscribe(from method: String) {
        invokedMethods.append(.unsubscribe)
    }
}

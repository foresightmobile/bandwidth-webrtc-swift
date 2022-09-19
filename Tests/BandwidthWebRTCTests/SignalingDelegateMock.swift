//
//  SignalingDelegateMock.swift
//  
//
//  Created by user on 18.09.2022.
//

import Foundation
@testable import BandwidthWebRTC

final class SignalingDelegateMock: SignalingDelegate {
    // MARK: - Types
    enum DelegateMethod: Equatable {
        case didRecieveOfferSDP(parameters: BandwidthWebRTC.SDPOfferParams)
    }
    
    // MARK: - Public properties
    private(set) var invokedMethod: DelegateMethod?
    var shouldReturnStubData: StubState<SDPOfferParams> = .none
    
    // MARK: - `SignalingDelegate` Protocol
    func signaling(_ signaling: BandwidthWebRTC.SignalingProvider, didRecieveOfferSDP parameters: BandwidthWebRTC.SDPOfferParams) {
        
        switch shouldReturnStubData {
        case .none:
            invokedMethod = .didRecieveOfferSDP(parameters: parameters)
        case .some(let stub):
            invokedMethod = .didRecieveOfferSDP(parameters: stub)
        }
    }
}

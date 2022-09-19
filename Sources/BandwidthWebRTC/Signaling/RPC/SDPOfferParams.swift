//
//  SDPOfferParams.swift
//  
//
//  Created by Michael Hamer on 5/11/21.
//

import Foundation

public struct SDPOfferParams: Codable, Equatable {
    let endpointId: String
    let sdpOffer: String
    let sdpRevision: Int
    let streamMetadata: [String: StreamMetadata]
}

//
//  OfferSDPResult.swift
//  
//
//  Created by Michael Hamer on 12/15/20.
//

import Foundation

public struct OfferSDPResult: Decodable, Equatable {
    let endpointId: String
    let sdpAnswer: String
    let streamMetadata: [String: StreamMetadata]
}

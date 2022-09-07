//
//  EndpointType.swift
//  
//
//  Created by Artem Grebinik on 05.09.2022.
//

import Foundation

//MARK: - EndpointType

public enum EndpointType {
    case url(URL)
    case token(String)
}

extension EndpointType {
    var url: URL? {
        switch self {
        case let .url(uRL):
            return uRL
        case let .token(token):
            let version = BandwidthKit.sdkVersion
            let endpoint = BandwidthEndpoint.using(token: token, sdkVersion: version)
            return endpoint.url
        }
    }
}

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
    case token(String, host: HostEnvironment)
}

extension EndpointType {
    var url: URL? {
        switch self {
        case let .url(uRL):
            return uRL
        case let .token(token, host):
            let version = BandwidthKit.sdkVersion
            let endpoint = BandwidthEndpoint.using(token: token, sdkVersion: version, host: host)
            return endpoint.url
        }
    }
}

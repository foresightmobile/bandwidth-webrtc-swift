//
//  BandwidthEndpoint.swift
//  
//
//  Created by Artem Grebinik on 05.09.2022.
//

import Foundation

//MARK: - BandwidthEndpoint
struct BandwidthEndpoint {
    let path: String
    let queryItems: [URLQueryItem]
    let hostUrl: String
}

extension BandwidthEndpoint {
    static func using(token: String, sdkVersion: String, uniqueId: String = UUID().uuidString, host: HostEnvironment) -> BandwidthEndpoint {
        return BandwidthEndpoint(
            path: "/v3",
            queryItems: [
                URLQueryItem(name: "token", value: token),
                URLQueryItem(name: "sdkVersion", value: sdkVersion),
                URLQueryItem(name: "uniqueId", value: uniqueId)
            ],
            hostUrl: host.hostUrl
        )
    }
}

extension BandwidthEndpoint {
    var url: URL? {
        var components = URLComponents()
        components.scheme = "wss"
        components.host = hostUrl
        components.path = path
        components.queryItems = queryItems

        return components.url
    }
}

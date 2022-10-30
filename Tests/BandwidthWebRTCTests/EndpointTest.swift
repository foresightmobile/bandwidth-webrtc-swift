//
//  EndpointTest.swift
//  
//
//  Created by user on 18.09.2022.
//

import XCTest
@testable import BandwidthWebRTC

final class EndpointTest: XCTestCase {

    func testBandwidthEndpoint() {
        let sdkVersion = UUID().uuidString
        let token = UUID().uuidString
        let uniqueId = UUID().uuidString
        
        let stubUrl = URL(string: "https://www.bandwidth.com")!
        let urlEndpoint = EndpointType.url(stubUrl)
        
        let bandwidthTokenStubUrl = URL(string: "wss://device.webrtc.bandwidth.com/v3?token=\(token)&sdkVersion=\(sdkVersion)&uniqueId=\(uniqueId)")!
        let bandwidthUrl = BandwidthEndpoint.using(token: token, sdkVersion: sdkVersion, uniqueId: uniqueId, host: .live).url
       
        XCTAssertEqual(bandwidthTokenStubUrl, bandwidthUrl)
        XCTAssertEqual(stubUrl, urlEndpoint.url)
    }

}

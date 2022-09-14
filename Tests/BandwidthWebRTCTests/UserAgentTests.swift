//
//  UserAgentTests.swift
//  
//
//  Created by Michael Hamer on 6/1/21.
//

import XCTest
@testable import BandwidthWebRTC

final class UserAgentTests: XCTestCase {
    func testDefaultBuildResult() {
        let packageName = "TestPackageName"
        let version = "7.7.7"
        
        let userAgent = UserAgent(from: Bundle.module.url(forResource: "Settings", withExtension: "plist"))
        
        XCTAssertEqual(userAgent.build(packageName: packageName), "\(packageName) \(version)")
    }
    
    func testBandwidthEndpoint() {
        let sdkVersion = UUID().uuidString
        let token = UUID().uuidString
        let uniqueId = UUID().uuidString
        
        let stubUrl = URL(string: "https://www.bandwidth.com")!
        let urlEndpoint = EndpointType.url(stubUrl)
        
        let bandwidthTokenStubUrl = URL(string: "wss://device.webrtc.bandwidth.com/v3?token=\(token)&sdkVersion=\(sdkVersion)&uniqueId=\(uniqueId)")!
        let bandwidthUrl = BandwidthEndpoint.using(token: token, sdkVersion: sdkVersion, uniqueId: uniqueId).url
       
        XCTAssertEqual(bandwidthTokenStubUrl, bandwidthUrl)
        XCTAssertEqual(stubUrl, urlEndpoint.url)
    }
}

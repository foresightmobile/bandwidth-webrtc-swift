//
//  RegExTests.swift
//  
//
//  Created by user on 16.09.2022.
//

import XCTest
@testable import BandwidthWebRTC

final class RegExTests: XCTestCase {

    func testRegExPattern_isMatchSuccessfully() {
        let stubRegExPattern = "a=(?:sendrecv|recvonly|sendonly|inactive)"
        let stubString = "This test must contain a regular expression (a=recvonly) pattern in order to pass the test."
        let isMatch = stubString.isMatch(pattern: stubRegExPattern)
        XCTAssert(isMatch, #function)
    }
    
    func testRegExPattern_isMatchFailed() {
        let stubRegExPattern = "a=(?:sendrecv|recvonly|sendonly|inactive)"
        let stubString = "This test must not contain a regular expression (a=) pattern in order to pass the test."
        let isMatch = stubString.isMatch(pattern: stubRegExPattern)
        XCTAssertNotEqual(isMatch, true, #function)
    }
    
    func testRegExPattern_matchesFailed() {
        let stubRegExPattern = "m=.*?(?=m=|$)"
        let stubString1 = "a=test"
        let stubString2 = "a=setup:passive"
        let stubString3 = "o=bandwidth-webrtc-client 111111111 0 IN IP4 0.0.0.0"
        
        let matches1 = stubString1.matches(pattern: stubRegExPattern, options: .dotMatchesLineSeparators)

        let matches2 = stubString2.matches(pattern: stubRegExPattern, options: .dotMatchesLineSeparators)

        let matches3 = stubString3.matches(pattern: stubRegExPattern, options: .dotMatchesLineSeparators)

        XCTAssertEqual(matches1.count, 0, #function)
        XCTAssertEqual(matches2.count, 0, #function)
        XCTAssertEqual(matches3.count, 0, #function)
    }
    
    func testRegExPattern_matchesSuccessfully() {
        let stubRegExPattern = "m=.*?(?=m=|$)"
        let stubString1 = "m=test"
        let stubString2 = "m=setup:passive"
        let stubString3 = "m=bandwidth-webrtc-client 111111111 0 IN IP4 0.0.0.0"
        
        let matches1 = stubString1.matches(pattern: stubRegExPattern, options: .dotMatchesLineSeparators)

        let matches2 = stubString2.matches(pattern: stubRegExPattern, options: .dotMatchesLineSeparators)

        let matches3 = stubString3.matches(pattern: stubRegExPattern, options: .dotMatchesLineSeparators)

        XCTAssertNotEqual(matches1.count, 0, #function)
        XCTAssertNotEqual(matches2.count, 0, #function)
        XCTAssertNotEqual(matches3.count, 0, #function)
    }
}

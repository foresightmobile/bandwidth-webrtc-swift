//
//  JoinCallResponse.swift
//  BandwidthSwiftUISample
//
//  Created by user on 04.10.2022.
//

import Foundation

struct JoinCallResponse: Codable {
    typealias Token = String
    
    var phoneNumber: String?
    var participantId: String?
    var conferenceCode: String?
    var websocketUrl: String?
    var conferenceId: String?
    var deviceToken: Token
}

struct ConferenceInfo: Codable {
//    var serverPath: String
    static var serverPathTemp: String {
        return "https://webrtc-sample-adzgv75fpa-nw.a.run.app/conferences/foresightdemo/participants"
//        return "https://webrtc-sample-adzgv75fpa-nw.a.run.app/foresightdemo"
    }
    
//https://meet.webrtc.bandwidth.com/conferences/demo/participants
}

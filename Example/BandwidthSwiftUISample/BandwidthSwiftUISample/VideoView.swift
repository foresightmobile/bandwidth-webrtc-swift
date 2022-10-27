//
//  VideoView.swift
//  BandwidthSwiftUISample
//
//  Created by user on 04.10.2022.
//

import SwiftUI
import UIKit
import WebRTC

struct VideoView: UIViewRepresentable {
    
    let videoTrack: RTCVideoTrack?
    @Binding var refreshVideoTrack: Bool
    let backgroundColor: UIColor
    
    func makeUIView(context: Context) -> RTCMTLVideoView {

        let renderer = RTCMTLVideoView()
        
        renderer.videoContentMode = .scaleAspectFill
        
        renderer.backgroundColor = backgroundColor
    
        return renderer
    }
    
    func updateUIView(_ view: RTCMTLVideoView, context: Context) {
        if refreshVideoTrack {
            videoTrack?.add(view)
            refreshVideoTrack = false
        }
    }
}


//
//  ViewModel.swift
//  BandwidthExample
//
//  Created by Artem Grebinik on 06.06.2022.
//

import Foundation
import WebRTC
import BandwidthWebRTC

class ViewModel: ObservableObject {
    
    @Published var remoteVideoTrack: RTCVideoTrack?
    @Published var localVideoTrack: RTCVideoTrack?
    
    @Published var refreshRemoteVideoTrack: Bool = false
    @Published var refreshLocalVideoTrack: Bool = false
    
    
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var speaker = false
    
    private let bandwidth: BandwidthProvider
    

    init() {
        self.bandwidth = BandwidthKit.getBandwidth()
        self.bandwidth.delegate = self
    }
    
    private var capturer: RTCCameraVideoCapturer?
    private var devicePosition: AVCaptureDevice.Position = .front
    
    
    func join() {
        if isConnected {
            bandwidth.disconnect()
            isConnected = false
        } else {
            getToken { [weak self] token in
                guard let self = self else { return }

                self.bandwidth.connect(with: .token("")) { result in
                    switch result {
                    case .success:
                        self.bandwidth.publish(alias: "sample") { stream in
                            DispatchQueue.main.async {
                                let videoTrack = stream.mediaStream.videoTracks.first
                                self.localVideoTrack = videoTrack
                                self.setSource(source: videoTrack?.source)
                                self.refreshLocalVideoTrack = true
                                
                                self.refreshRemoteVideoTrack = true
                                
                                self.capture(device: self.devicePosition)
                                self.isConnected = true
                            }
                        }
                    case .failure(let error):
                        print("localizedDescription: ",error.localizedDescription)
                    }
                }
            }
        }
    }
    
    private func getToken(completion: @escaping (JoinCallResponse) -> Void) {
        print("Fetching media token from server application.")
        
        guard let url = URL(string: ConferenceInfo.serverPathTemp) else {
            return
        }
        print("url:",url)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { data, response, error in

            guard let data = data,
                    let joinCallResponse = try? JSONDecoder().decode(JoinCallResponse.self, from: data) else {
                fatalError("Failed to decode the join call response.")
            }

            DispatchQueue.main.async {
                completion(joinCallResponse)
            }
        }.resume()
    }
    
    private func capture(device position: AVCaptureDevice.Position) {
        capturer?.stopCapture()
        
        guard let device = RTCCameraVideoCapturer.captureDevices().first(where: { $0.position == position }) else {
            return
        }
        
        // Grab the highest resolution available.
        guard let format = RTCCameraVideoCapturer.supportedFormats(for: device)
            .sorted(by: { CMVideoFormatDescriptionGetDimensions($0.formatDescription).width < CMVideoFormatDescriptionGetDimensions($1.formatDescription).width })
            .last else {
            return
        }
        
        // Grab the highest fps available.
        guard let fps = format.videoSupportedFrameRateRanges
            .compactMap({ $0.maxFrameRate })
            .sorted()
            .last else {
            return
        }
        
        capturer?.startCapture(with: device, format: format, fps: Int(fps))
    }
    
    
    func setSource(source: RTCVideoSource?) {
        self.capturer = RTCCameraVideoCapturer()
        self.capturer?.delegate = source
    }
    
    func toggleSpeaker() {
        if isConnected {
            speaker.toggle()
            bandwidth.setSpeaker(speaker)
        }
    }
}

extension ViewModel: BandwidthProviderDelegate {
    func bandwidth(_ bandwidth: BandwidthProvider, streamAvailable stream: RTCStream) {
        DispatchQueue.main.async {
            let videoTrack = stream.mediaStream.videoTracks.first
            self.remoteVideoTrack = videoTrack
            self.refreshRemoteVideoTrack = true
        }
    }
    
    func bandwidth(_ bandwidth: BandwidthProvider, streamUnavailable stream: RTCStream) {
        DispatchQueue.main.async {
//            self.remoteVideoTrack?.remove(self.remoteRenderer)
//            self.remoteVideoTrack = nil
//            self.refreshRemoteVideoTrack = true
//            self.shouldDisconect = true
        }
    }
}


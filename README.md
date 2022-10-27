# Bandwidth WebRTC Swift

Bandwidth WebRTC Swift is an open-source implementation of [Bandwidth WebRTC](https://dev.bandwidth.com/webrtc/about.html) suitable for iOS devices.

In order to take advantage of this package a Bandwidth account with WebRTC Audio and/or Video must be enabled.

## Quick Start

```swiftUI
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

                self.bandwidth.connect(with: .token(token.deviceToken)) { result in
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
    
    func getToken(completion: @escaping (String) -> Void) {
        // Return a Bandwidth WebRTC participant token from your application server. https://dev.bandwidth.com/webrtc/methods/participants/createParticipant.html
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
        DispatchQueue.main.async {}
    }
}

```
```swift

import WebRTC
import BandwidthWebRTC

class WebRTCService {
    let bandwidth = BandwidthKit.getBandwidth()
    
    var localVideoTrack: RTCVideoTrack?
    var localCameraVideoCapturer: RTCCameraVideoCapturer?

    var remoteVideoTrack: RTCVideoTrack?

    init() {
        bandwidth.delegate = self

        getToken { token in
            try? self.bandwidth.connect(using: token) {
                self.bandwidth.publish(alias: "Bolg") { stream in
                    self.localVideoTrack = stream.mediaStream.track as? RTCVideoTrack
                    // localRenderer should be a UIView of type RTCVideoRenderer. This is the view which displays the local video.
                    self.localVideoTrack?.add(self.localRenderer)

                    self.localCameraVideoCapturer = RTCCameraVideoCapturer()
                    self.localCameraVideoCapturer?.delegate = self.localVideoTrack?.source

                    // Grab the front facing camera. TODO: Add support for additional cameras.
                    guard let device = RTCCameraVideoCapturer.captureDevices().first(where: { $0.position == .front }) else {
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
                    
                    // Start capturing local video with the given parameters.
                    self.localCameraVideoCapturer?.startCapture(with: device, format: format, fps: Int(fps))
                }
            }
        }
    }

    func getToken(completion: @escaping (String) -> Void) {
        // Return a Bandwidth WebRTC participant token from your application server. https://dev.bandwidth.com/webrtc/methods/participants/createParticipant.html
    }
}

extension WebRTCService: RTCBandwidthDelegate {
    func bandwidth(_ bandwidth: RTCBandwidth, streamAvailable stream: RTCStream) {
        if let remoteVideoTrack = stream.mediaStream.track as? RTCVideoTrack {
            self.remoteVideoTrack = remoteVideoTrack
            
            DispatchQueue.main.async {
                // remoteRenderer should be a UIView of type RTCVideoRenderer. This is the view which displays the remote video.
                self.remoteVideoTrack?.add(self.remoteRenderer)
            }
        }
    }

    func bandwidth(_ bandwidth: RTCBandwidth, streamUnavailable stream: RTCStream) {
        
    }
}
```

## Samples

A number of samples using Bandwidth WebRTC Swift may be found within [Bandwidth-Samples](https://github.com/Bandwidth-Samples).

## Compatibility

Bandwidth WebRTC Swift follows [SemVer 2.0.0](https://semver.org/#semantic-versioning-200).

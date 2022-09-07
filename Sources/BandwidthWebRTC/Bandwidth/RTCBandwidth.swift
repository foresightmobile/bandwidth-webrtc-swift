//
//  RTCBandwidth.swift
//
//
//  Created by Michael Hamer on 12/17/20.
//

import Foundation
import WebRTC

class RTCBandwidth: NSObject, BandwidthProvider {
    /**
        Signaling server.
     
        Used to receive media.
        Should use a SignalingDelegate to get parameters: SDPOfferParams:

            let signaling = Signaling()
            signaling?.delegate = self
    */
    private var signaling: Signaling?
    
    /**
     Initialize object with injectable video encoder/decoder factories
     
     This encoder/decoder factory include support for all codecs bundled with WebRTC. If using custom
     codecs, create custom implementations of RTCVideoEncoderFactory and
     RTCVideoDecoderFactory.

     - Parameters:
        - encoderFactory:
        - decoderFactory:

     - Returns: RTCPeerConnectionFactory
     */
    private static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        
        return RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
    }()
    
    /**
     Defines the parameters to configure how a new RTCPeerConnection is created.

     - Parameters:
        - sdpSemantics: Represents the chosen SDP semantics for the RTCPeerConnection.
        - iceServers: An array of Ice Servers available to be used by ICE.
        - iceTransportPolicy: Represents the ice transport policy. This exposes the same states in C++, which includes one more state than what exists in the W3C spec.
        - bundlePolicy:  Represents the media-bundling policy to use when gathering ICE candidates.
        - rtcpMuxPolicy:  Represents the rtcp mux policy to use when gathering ICE candidates.
        - candidateNetworkPolicy: Represents the candidate network policy.
        - tcpCandidatePolicy: Represents the tcp candidate policy.
        - continualGatheringPolicy: Represents the continual gathering policy.
        - keyType: Represents the encryption key type. Used to generate SSL identity. Default is ECDSA.

     - Returns: RTCConfiguration
     */
    private let configuration: RTCConfiguration = {
        var configuration = RTCConfiguration()
        configuration.sdpSemantics = .unifiedPlan
        configuration.iceServers = []
        configuration.iceTransportPolicy = .all
        configuration.bundlePolicy = .maxBundle
        configuration.rtcpMuxPolicy = .require
        return configuration
    }()
    
    /**
     Initialize with mandatory and/or optional constraints.
     The value for this key should be a base64 encoded string containing the data from the serialized configuration proto.\
    
     - Parameters:
        - mandatoryConstraints:
        - optionalConstraints:
     
     - Returns: RTCMediaConstraints
     */
    private let mediaConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: ["DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue])
    
    /// One peer for all published (outgoing) streams, one for all subscribed (incoming) streams.
    private var publishingPeerConnection: RTCPeerConnection?
    private var subscribingPeerConnection: RTCPeerConnection?
    
    /// Standard data channels used for platform diagnostics and health checks.
    private var publishHeartbeatDataChannel: RTCDataChannel?
    private var publishDiagnosticsDataChannel: RTCDataChannel?
    private var publishedDataChannels: [String: RTCDataChannel] = [:]
    private var subscribeHeartbeatDataChannel: RTCDataChannel?
    private var subscribeDiagnosticsDataChannel: RTCDataChannel?
    private var subscribedDataChannels: [String: RTCDataChannel] = [:]
    
    /// Published (outgoing) streams keyed by media stream id (msid).
    private var publishedStreams: [String: PublishedStream] = [:]
    /// Subscribed (incoming) streams keyed by media stream id (msid).
    private var subscribedStreams: [String: StreamMetadata] = [:]
    
    /// Keep track of our available streams. Prevents duplicate stream available / unavailable events.
    private var availableMediaStreams: [String: RTCMediaStream] = [:]
    
    #if os(iOS)
    private let audioSession =  RTCAudioSession.sharedInstance()
    #endif
    
    private let audioQueue = DispatchQueue(label: "audio")

    var delegate: BandwidthProviderDelegate?
    var dataChannelDelegate: DataChannelDelegate?
    var peerConnectionDelegate: PeerConnectionDelegate?
    
    override init() {
        super.init()
        configureAudioSession()
    }
    
    /**
     Connect to the signaling server to start publishing media.
     Uses token and sdkVersion.
     
     - Parameters:
       - token: Token returned from Bandwidth's servers giving permission to access WebRTC.
       - completion: The completion handler to call when the connect request is complete.
     */
    
    /**
     Connect to the signaling server to start publishing media.
     
     - Parameters:
       - url: Complete URL containing everything required to access WebRTC.
       - completion: The completion handler to call when the connect request is complete.
     */
    func connect(with endpointType: EndpointType, completion: @escaping (Result<(), Error>) -> Void) {

        guard let url = endpointType.url else {
            completion(.failure(SignalingError.invalidWebSocketURL))
            return
        }
        signaling = Signaling()
        signaling?.delegate = self
        
        signaling?.connect(to: url) { result in
            completion(result)
        }
    }
    
    /// Disconnect from Bandwidth's WebRTC signaling server and remove all connections.
    func disconnect() {
        signaling?.disconnect()
        cleanupPublishedStreams(publishedStreams: publishedStreams)
        publishingPeerConnection?.close()
        subscribingPeerConnection?.close()
        publishingPeerConnection = nil
        subscribingPeerConnection = nil
    }

    /**
     Publishing RTCStream that containce
     mediaType, RTCMediaStream, alias and participantId
     - Parameters:
       - alias:
       - completion:
     */
    func publish(alias: String?, completion: @escaping (RTCStream) -> Void) {
        setupPublishingPeerConnection {
            let mediaStream = RTCBandwidth.factory.mediaStream(withStreamId: UUID().uuidString)
            
            let audioTrack = RTCBandwidth.factory.audioTrack(with: RTCBandwidth.factory.audioSource(with: nil), trackId: UUID().uuidString)
            mediaStream.addAudioTrack(audioTrack)
            
            let videoTrack = RTCBandwidth.factory.videoTrack(with: RTCBandwidth.factory.videoSource(), trackId: UUID().uuidString)
            mediaStream.addVideoTrack(videoTrack)
            
            self.addStreamToPublishingPeerConnection(mediaStream: mediaStream)
            
            let publishMetadata = StreamPublishMetadata(alias: alias)
            self.publishedStreams[mediaStream.streamId] = PublishedStream(mediaStream: mediaStream, metadata: publishMetadata)
            
            self.offerPublishSDP { result in
                let stream = RTCStream(mediaTypes: result.streamMetadata[mediaStream.streamId]?.mediaTypes ?? [.application],
                                       mediaStream: mediaStream,
                                       alias: alias,
                                       participantId: nil)
                
                completion(stream)
            }
        }
    }
    
    /**
     Gives a new *heartbeat* data channel with the given label and configuration

     - Parameters:
       - peerConnection:

     - Returns: RTCDataChannel
     */
    private func addHeartbeatDataChannel(peerConnection: RTCPeerConnection) -> RTCDataChannel? {
        let configuration = RTCDataChannelConfiguration()
        configuration.channelId = 0
        configuration.isNegotiated = true
        configuration.protocol = "udp"
        
        return peerConnection.dataChannel(forLabel: "__heartbeat__", configuration: configuration)
    }
    
    /**
     Gives a new *diagnostics* data channel with the given label and configuration
     - Parameters:
       - peerConnection:

     - Returns: RTCDataChannel
     */
    private func addDiagnosticsDataChannel(peerConnection: RTCPeerConnection) -> RTCDataChannel? {
        let configuration = RTCDataChannelConfiguration()
        configuration.channelId = 1
        configuration.isNegotiated = true
        configuration.protocol = "udp"
        
        let dataChannel = peerConnection.dataChannel(forLabel: "__diagnostics__", configuration: configuration)
        dataChannel?.delegate = self
        
        return dataChannel
    }
    
    /// Publish / (re)publish existing media streams.
    private func setupPublishingPeerConnection(completion: @escaping () -> Void) {
        guard publishingPeerConnection == nil else {
            completion()
            return
        }
        
        publishingPeerConnection = RTCBandwidth.factory.peerConnection(with: configuration, constraints: mediaConstraints, delegate: self)
        
        if let publishingPeerConnection = publishingPeerConnection {
            if let heartbeatDataChannel = addHeartbeatDataChannel(peerConnection: publishingPeerConnection) {
                publishedDataChannels[heartbeatDataChannel.label] = heartbeatDataChannel
                publishHeartbeatDataChannel = heartbeatDataChannel
            }
            
            if let diagnosticsDataChannel = addDiagnosticsDataChannel(peerConnection: publishingPeerConnection) {
                publishedDataChannels[diagnosticsDataChannel.label] = diagnosticsDataChannel
                publishDiagnosticsDataChannel = diagnosticsDataChannel
            }
        }
        
        offerPublishSDP { _ in
            
            // (Re)publish any existing media streams.
            for publishedStream in self.publishedStreams {
                self.addStreamToPublishingPeerConnection(mediaStream: publishedStream.value.mediaStream)
                
                self.offerPublishSDP { _ in
                    completion()
                }
            }
            
            completion()
        }
    }
    
    /// Publish / (re)publish existing media streams.
    private func setupSubscribingPeerConnection() {
        subscribingPeerConnection = RTCBandwidth.factory.peerConnection(with: configuration, constraints: mediaConstraints, delegate: self)
        
        if let subscribingPeerConnection = subscribingPeerConnection {
            if let heartbeatDataChannel = addHeartbeatDataChannel(peerConnection: subscribingPeerConnection) {
                subscribedDataChannels[heartbeatDataChannel.label] = heartbeatDataChannel
                subscribeHeartbeatDataChannel = heartbeatDataChannel
            }
            
            if let diagnosticsDataChannel = addDiagnosticsDataChannel(peerConnection: subscribingPeerConnection) {
                subscribedDataChannels[diagnosticsDataChannel.label] = diagnosticsDataChannel
                subscribeDiagnosticsDataChannel = diagnosticsDataChannel
            }
        }
    }
    
    private func offerPublishSDP(restartICE: Bool = false, completion: @escaping (OfferSDPResult) -> Void) {
        let mandatoryConstraints = [
            kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueFalse,
            kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueFalse,
            kRTCMediaConstraintsVoiceActivityDetection: kRTCMediaConstraintsValueTrue,
            kRTCMediaConstraintsIceRestart: restartICE ? kRTCMediaConstraintsValueTrue : kRTCMediaConstraintsValueFalse
        ]
        
        let mediaConstraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
        
        publishingPeerConnection?.offer(for: mediaConstraints, completionHandler: { localSDPOffer, error in
            guard let localSDPOffer = localSDPOffer else {
                return
            }
            
            let mediaStreams = self.publishedStreams.mapValues { $0.metadata }
            let dataChannels = self.publishedDataChannels.mapValues { DataChannelPublishMetadata(label: $0.label, streamId: $0.channelId) }
            let publishMetadata = PublishMetadata(mediaStreams: mediaStreams, dataChannels: dataChannels)
            
            self.signaling?.offer(sdp: localSDPOffer.sdp, publishMetadata: publishMetadata) { result in
                
                switch result {
                case .success(let result):
                    self.publishingPeerConnection?.setLocalDescription(localSDPOffer) { error in
                        guard let result = result else {
                            return
                        }
                        
                        let sdp = RTCSessionDescription(type: .answer, sdp: result.sdpAnswer)
                        
                        self.publishingPeerConnection?.setRemoteDescription(sdp) { error in
                            completion(result)
                        }
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        })
    }
    
    /// Stops the signaling server from publishing `streamId` and removes associated tracks.
    ///
    /// - Parameter streamId: The stream ids for the published streams.
    func unpublish(streamIds: [String], completion: @escaping () -> Void) {
        let publishedStreams = self.publishedStreams.filter { streamIds.contains($0.key) }
        cleanupPublishedStreams(publishedStreams: publishedStreams)
        
        offerPublishSDP { _ in
            completion()
        }
    }
    
    private func addStreamToPublishingPeerConnection(mediaStream: RTCMediaStream) {
        for track in mediaStream.audioTracks + mediaStream.videoTracks {
            let transceiverInit = RTCRtpTransceiverInit()
            transceiverInit.direction = .sendOnly
            transceiverInit.streamIds = [mediaStream.streamId]

            publishingPeerConnection?.addTransceiver(with: track, init: transceiverInit)
        }
    }
    
    private func cleanupPublishedStreams(publishedStreams: [String: PublishedStream]) {
        for publishedStream in publishedStreams {
            let transceivers = publishingPeerConnection?.transceivers ?? []
            for transceiver in transceivers {
                let mediaStream = publishedStream.value.mediaStream
                
                for audioTrack in mediaStream.audioTracks {
                    if transceiver.sender.track == audioTrack {
                        publishingPeerConnection?.removeTrack(transceiver.sender)
                        transceiver.stopInternal()
                    }
                }
                
                for videoTrack in mediaStream.videoTracks {
                    if transceiver.sender.track == videoTrack {
                        publishingPeerConnection?.removeTrack(transceiver.sender)
                        transceiver.stopInternal()
                    }
                }
            }
            self.publishedStreams.removeValue(forKey: publishedStream.key)
        }
    }
    
    // MARK: Media
    
    func configureAudioSession() {
        #if os(iOS)
        audioSession.lockForConfiguration()
        
        defer {
            audioSession.unlockForConfiguration()
        }
        
        do {
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord.rawValue)
            try audioSession.setMode(AVAudioSession.Mode.voiceChat.rawValue)
        } catch let error {
            debugPrint("Error updating AVAudioSession category: \(error.localizedDescription)")
        }
        #endif
    }
    
    #if os(iOS)
    /// Determine whether the device's speaker should be in an enabled state.
    ///
    /// - Parameter isEnabled: A Boolean value indicating whether the device's speaker is in the enabled state.
    func setSpeaker(_ isEnabled: Bool) {
        audioQueue.async {
            defer {
                RTCAudioSession.sharedInstance().unlockForConfiguration()
            }
            
            RTCAudioSession.sharedInstance().lockForConfiguration()
            do {
                try RTCAudioSession.sharedInstance().overrideOutputAudioPort(isEnabled ? .speaker : .none)
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }
    #endif
    
    private func handleSubscribeOfferSDP(parameters: SDPOfferParams, completion: @escaping () -> Void) {
        subscribedStreams = parameters.streamMetadata
        
        if subscribingPeerConnection == nil {
            setupSubscribingPeerConnection()
        }
        
        let mungedSDP = setSDPMediaSetup(sdp: parameters.sdpOffer, considerDirection: true, withTemplate: "a=setup:actpass")
        let mungedSessionDescription = RTCSessionDescription(type: .offer, sdp: mungedSDP)
        
        subscribingPeerConnection?.setRemoteDescription(mungedSessionDescription) { error in
            if let error = error {
                debugPrint(error.localizedDescription)
            } else {
                self.subscribingPeerConnection?.answer(for: self.mediaConstraints) { sessionDescription, error in
                    if let error = error {
                        debugPrint(error.localizedDescription)
                    } else {
                        guard let sessionDescription = sessionDescription else {
                            return
                        }
                        
                        let mungedSDP = self.setSDPMediaSetup(sdp: sessionDescription.sdp, considerDirection: false, withTemplate: "a=setup:passive")
                        let mungedSessionDescription = RTCSessionDescription(type: sessionDescription.type, sdp: mungedSDP)
                        
                        self.subscribingPeerConnection?.setLocalDescription(mungedSessionDescription) { error in
                            if let error = error {
                                debugPrint(error.localizedDescription)
                            } else {
                                self.signaling?.answer(sdp: mungedSessionDescription.sdp) { _ in
                                    completion()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func setSDPMediaSetup(sdp: String, considerDirection: Bool, withTemplate template: String) -> String {
        var mungedSDP = sdp
        
        // Match all media descriptions within the sdp.
        let mediaMatches = sdp.matches(pattern: "m=.*?(?=m=|$)", options: .dotMatchesLineSeparators)
        
        // Iterate the media descriptions in reverse as we'll potentially be modifying them.
        for mediaMatch in mediaMatches.reversed() {
            guard let mediaRange = Range(mediaMatch.range, in: sdp) else {
                continue
            }
            
            let media = sdp[mediaRange]
            
            // Either do not consider the direction or only act on media descriptions without a direction.
            if !considerDirection || !String(media).isMatch(pattern: "a=(?:sendrecv|recvonly|sendonly|inactive)") {
                if let replaceRegex = try? NSRegularExpression(pattern: "a=setup:(?:active)", options: .caseInsensitive) {
                    mungedSDP = replaceRegex.stringByReplacingMatches(in: mungedSDP, options: [], range: mediaMatch.range, withTemplate: template)
                }
            }
        }
        
        return mungedSDP
    }
}

//MARK: - RTCPeerConnectionDelegate
extension RTCBandwidth: RTCPeerConnectionDelegate {
    
    /** Called when the SignalingState changed. */
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        debugPrint("peerConnection new signaling state: \(stateChanged)")
        peerConnectionDelegate?.bandwidth(self, didChangeSignalingState: stateChanged)
    }
    
    @available(*, deprecated)
    /** Called when media is received on a new stream from remote peer. */
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        debugPrint("peerConnection did add stream")
        peerConnectionDelegate?.bandwidth(self, didAddStream: stream)
    }

    @available(*, deprecated)
    /** Called when a remote peer closes a stream.
     *  This is not called when RTCSdpSemanticsUnifiedPlan is specified.
     */
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        debugPrint("peerConnection did remove stream")
        peerConnectionDelegate?.bandwidth(self, didRemoveStream: stream)
    }
    
    /** Called when negotiation is needed, for example ICE has restarted. */
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        debugPrint("peerConnection should negotiate")
        peerConnectionDelegate?.bandwidth(self, peerConnectionShouldNegotiate: peerConnection)
    }
    
    /** Called any time the IceConnectionState changes. */
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        debugPrint("peerConnection new connection state: \(newState)")
        peerConnectionDelegate?.bandwidth(self, didChangeConnectionState: newState)
    }

    /** Called any time the IceGatheringState changes. */
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        debugPrint("peerConnection new gathering state: \(newState)")
        peerConnectionDelegate?.bandwidth(self, didChangeIceGatheringState: newState)
    }
    
    /** New ice candidate has been found. */
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        debugPrint("peerConnection didGenerateIceCandidate \(candidate.sdp)")
        peerConnectionDelegate?.bandwidth(self, didGenerateIceCandidate: candidate)
    }

    /** Called when a group of local Ice candidates have been removed. */
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        debugPrint("peerConnection did remove candidate(s)")
        peerConnectionDelegate?.bandwidth(self, didRemoveIceCandidates: candidates)
    }
    
    /** New data channel has been opened. */
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        debugPrint("peerConnection did open data channel")
        peerConnectionDelegate?.bandwidth(self, didOpenDataChannel: dataChannel)
    }
    
    /** Called when a receiver and its track are created. */
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd rtpReceiver: RTCRtpReceiver, streams mediaStreams: [RTCMediaStream]) {
        guard subscribingPeerConnection == peerConnection else {
            return
        }
        
        for mediaStream in mediaStreams {
            if availableMediaStreams.updateValue(mediaStream, forKey: mediaStream.streamId) == nil {
                let subscribedStream = subscribedStreams[mediaStream.streamId]
                
                let stream = RTCStream(mediaTypes: subscribedStream?.mediaTypes ?? [],
                                    mediaStream: mediaStream,
                                    alias: subscribedStream?.alias,
                                    participantId: subscribedStream?.participantId)
                
                delegate?.bandwidth(self, streamAvailable: stream)
            }
        }
    }
    
    /** Called when the receiver and its track are removed. */
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove rtpReceiver: RTCRtpReceiver) {
        guard subscribingPeerConnection == peerConnection else {
            return
        }
        
        guard let track = rtpReceiver.track else {
            return
        }
        
        let availableMediaStream = availableMediaStreams
            .first { $0.value.audioTracks.contains { $0.trackId == track.trackId } || $0.value.videoTracks.contains { $0.trackId == track.trackId } }
        
        if let availableMediaStream = availableMediaStream {
            let mediaStream = availableMediaStream.value
            
            let subscribedStream = subscribedStreams[mediaStream.streamId]
            
            let stream = RTCStream(mediaTypes: subscribedStream?.mediaTypes ?? [],
                                mediaStream: mediaStream,
                                alias: subscribedStream?.alias,
                                participantId: subscribedStream?.participantId)
            
            delegate?.bandwidth(self, streamUnavailable: stream)
            
            availableMediaStreams.removeValue(forKey: mediaStream.streamId)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCPeerConnectionState) {
        guard publishingPeerConnection == peerConnection else {
            return
        }

        if newState == .failed {
            offerPublishSDP(restartICE: true) { _ in

            }
        }
        peerConnectionDelegate?.bandwidth(self, didChangeConnectionState: newState)
    }
}

extension RTCBandwidth: RTCDataChannelDelegate {
    /// The data channel state changed.
    /// - Parameters:
    ///   - dataChannel:
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        debugPrint("dataChannel did change state: \(dataChannel.readyState)")
        dataChannelDelegate?.bandwidth(self, didChangeChannelState: dataChannel.readyState)
    }
    
    /// The data channel successfully received a data buffer.
    /// - Parameters:
    ///   - dataChannel:
    ///   - buffer:
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        debugPrint("Diagnostics Received: \(String(data: buffer.data, encoding: .utf8) ?? "")")
        dataChannelDelegate?.bandwidth(self, didReceiveData: buffer.data)
    }
    
    /// The data channel's |bufferedAmount| changed.
    /// - Parameters:
    ///   - dataChannel:
    ///   - amount:
    func dataChannel(_ dataChannel: RTCDataChannel, didChangeBufferedAmount amount: UInt64) {
        debugPrint("Diagnostics Received: BufferedAmount \(amount)")
        dataChannelDelegate?.bandwidth(self, didChangeBufferedAmount: amount)
    }
}

//MARK: - SignalingDelegate
extension RTCBandwidth: SignalingDelegate {
    /// The Signaling server callback.
    /// - Parameters:
    ///   - signaling:
    ///   - parameters:
    func signaling(_ signaling: Signaling, didRecieveOfferSDP parameters: SDPOfferParams) {
        handleSubscribeOfferSDP(parameters: parameters) {
            
        }
    }
}

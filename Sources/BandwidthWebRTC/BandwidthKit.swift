//
//  BandwidthKit.swift
//  
//
//  Created by Artem Grebinik on 06.09.2022.
//

import Foundation
import WebRTC

//MARK: - BandwidthKit Interface
public class BandwidthKit {
    private static let userAgent = UserAgent()
    
    /// provides the SDK version string by appending package name, device system name, device system version, and device model.
    public static var sdkVersion: String {
        return userAgent.build(packageName: "BandwidthWebRTCSwift")
    }

    /// Single point of entry for the bandwidth SDK
    public static func getBandwidth() -> BandwidthProvider {
        return RTCBandwidth()
    }
}

//MARK: - BandwidthProvider
public protocol BandwidthProvider: AnyObject {
    
    /// Determine whether the stream available / unavailable
    var delegate: BandwidthProviderDelegate? { get set }
   
    /// RTCDataChannelDelegate representation
    var dataChannelDelegate: DataChannelDelegate? { get set }
    
    /// RTCPeerConnectionDelegate representation
    var peerConnectionDelegate: PeerConnectionDelegate? { get set }
    
    /**
     Connect to the signaling server to start publishing media.
     
     - Parameters:
       - endpointType: Сonnection type. Сan be url or token
            - url: Complete URL containing everything required to access WebRTC.
            - token: Token returned from Bandwidth's servers giving permission to access WebRTC.
       - completion: The completion handler to call when the connect request is complete.
     */
    func connect(with endpointType: EndpointType, completion: @escaping (Result<(), Error>) -> Void)

    /// Disconnect from Bandwidth's WebRTC signaling server and remove all connections.
    func disconnect()
    
    /**
     Publishing RTCStream that containce mediaType, RTCMediaStream, alias and participantId
     - Parameters:
       - alias:
       - completion:
     */
    func publish(alias: String?, completion: @escaping (RTCStream) -> Void)
    
    /**
     Stops the signaling server from publishing `streamId` and removes associated tracks.
     - Parameters:
        - streamId: The stream ids for the published streams.
    */
    func unpublish(streamIds: [String], completion: @escaping () -> Void)

#if os(iOS)
    /**
     Determine whether the device's speaker should be in an enabled state.
     - Parameters:
        - isEnabled: A Boolean value indicating whether the device's speaker is in the enabled state.
    */
    func setSpeaker(_ isEnabled: Bool)
#endif
}

//MARK: - BandwidthProviderDelegate
public protocol BandwidthProviderDelegate: AnyObject {
    /**
     Determine whether the device's speaker should be in an enabled state.
     - Parameters:
        - stream: Determine whether the stream available
    */
    func bandwidth(_ bandwidth: BandwidthProvider, streamAvailable stream: RTCStream)
    
    /**
     Determine whether the device's speaker should be in an enabled state.
     - Parameters:
        - stream: Determine whether the stream unavailable
    */
    func bandwidth(_ bandwidth: BandwidthProvider, streamUnavailable stream: RTCStream)
}

//MARK: - DataChannelDelegate
public protocol DataChannelDelegate: AnyObject {

    /// The data channel successfully received a data buffer.
    /// - Parameters:
    ///   - data: NSData representation of the underlying buffer.
    func bandwidth(_ bandwidth: BandwidthProvider, didReceiveData data: Data)
    
    /// The data channel's |bufferedAmount| changed.
    /// - Parameters:
    ///   - amount: UInt64 representation of the  buffered Amount
    func bandwidth(_ bandwidth: BandwidthProvider, didChangeBufferedAmount amount: UInt64)
   
    /// The data channel state changed.
    /// - Parameters:
    ///   - state:The state of the data channel.
    func bandwidth(_ bandwidth: BandwidthProvider, didChangeChannelState state: RTCDataChannelState)
}

public extension DataChannelDelegate {
    func bandwidth(_ bandwidth: BandwidthProvider, didReceiveData data: Data) {}
    
    func bandwidth(_ bandwidth: BandwidthProvider, didChangeBufferedAmount amount: UInt64) {}
    
    func bandwidth(_ bandwidth: BandwidthProvider, didChangeChannelState state: RTCDataChannelState) {}
}

//MARK: - PeerConnectionDelegate
public protocol PeerConnectionDelegate: AnyObject {
    /// Called when the SignalingState changed.
    func bandwidth(_ bandwidth: BandwidthProvider, didChangeSignalingState state: RTCSignalingState)
 
    /// Called when media is received on a new stream from remote peer.
    func bandwidth(_ bandwidth: BandwidthProvider, didAddStream stream: RTCMediaStream)
  
    /// Called when a remote peer closes a stream.
    /// This is not called when RTCSdpSemanticsUnifiedPlan is specified.
    func bandwidth(_ bandwidth: BandwidthProvider, didRemoveStream stream: RTCMediaStream)
   
    /// Called when negotiation is needed, for example ICE has restarted.
    func bandwidth(_ bandwidth: BandwidthProvider, peerConnectionShouldNegotiate peerConnection:
                   RTCPeerConnection)
    
    /// Called any time the IceConnectionState changes.
    func bandwidth(_ client: BandwidthProvider, didChangeConnectionState state: RTCIceConnectionState)
    
    /// Called any time the IceGatheringState changes. 
    func bandwidth(_ client: BandwidthProvider, didChangeIceGatheringState state: RTCIceGatheringState)
    
    /// New ice candidate has been found
    func bandwidth(_ client: BandwidthProvider, didGenerateIceCandidate candidate: RTCIceCandidate)
    
    /// Called when a group of local Ice candidates have been removed.
    func bandwidth(_ client: BandwidthProvider, didRemoveIceCandidates: [RTCIceCandidate])
    
    /// New data channel has been opened. 
    func bandwidth(_ client: BandwidthProvider, didOpenDataChannel: RTCDataChannel)
    func bandwidth(_ client: BandwidthProvider, didChangeConnectionState state: RTCPeerConnectionState)
}

public extension PeerConnectionDelegate {
    func bandwidth(_ bandwidth: BandwidthProvider, didChangeSignalingState state: RTCSignalingState) {}
    
    func bandwidth(_ bandwidth: BandwidthProvider, didAddStream stream: RTCMediaStream) {}
    
    func bandwidth(_ bandwidth: BandwidthProvider, didRemoveStream stream: RTCMediaStream) {}
    
    func bandwidth(_ bandwidth: BandwidthProvider, peerConnectionShouldNegotiate peerConnection: RTCPeerConnection) {}
    
    func bandwidth(_ bandwidth: BandwidthProvider, didChangeConnectionState state: RTCIceConnectionState) {}
    
    func bandwidth(_ bandwidth: BandwidthProvider, didChangeIceGatheringState state: RTCIceGatheringState) {}
    
    func bandwidth(_ bandwidth: BandwidthProvider, didGenerateIceCandidate candidate: RTCIceCandidate) {}
    
    func bandwidth(_ bandwidth: BandwidthProvider, didRemoveIceCandidates: [RTCIceCandidate]) {}
    
    func bandwidth(_ bandwidth: BandwidthProvider, didOpenDataChannel: RTCDataChannel) {}
    
    func bandwidth(_ bandwidth: BandwidthProvider, didChangeConnectionState state: RTCPeerConnectionState) {}
}

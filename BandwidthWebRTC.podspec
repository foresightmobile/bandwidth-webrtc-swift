Pod::Spec.new do |s|
  s.name             = 'BandwidthWebRTC'
  s.version          = '1.0.0'
  s.summary          = 'Swift Client SDK. Easily build live audio or video experiences into your mobile app, game or website.'
  s.homepage         = 'https://github.com/foresightmobile/bandwidth-webrtc-swift'
  s.license          = { :type => 'MIT', :file => 'LICENSE.txt' }
  s.author           = 'Bandwidth'

  s.ios.deployment_target = '13.0'
  
  s.swift_version = '5.0'
  s.source           = { :git => 'https://github.com/foresightmobile/bandwidth-webrtc-swift.git', :tag => s.version.to_s }

  s.source_files = 'Sources/BandwidthWebRTC/**/*'
  s.exclude_files = "Sources/BandwidthWebRTC/**/*.plist"
 
  s.dependency 'JSONRPCWebSockets', '~> 1.0.1'
  s.dependency 'WebRTC-SDK', '~> 104.5112.04'

end





  

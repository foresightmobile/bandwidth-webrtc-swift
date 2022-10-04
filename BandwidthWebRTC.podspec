#
# Be sure to run `pod lib lint bandwidth-webrtc-swift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'BandwidthWebRTC'
  s.version          = '1.0.1'
  s.summary          = 'description for bandwidth-webrtc-swift.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/foresightmobile/bandwidth-webrtc-swift'
  s.license          = { :type => 'MIT', :file => 'LICENSE.txt' }
  s.author           = { 'artemHrebinikChisw' => '75477796+artemHrebinikChisw@users.noreply.github.com' }
  s.source           = { :git => 'https://github.com/foresightmobile/bandwidth-webrtc-swift.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'
  s.source_files = 'Sources/BandwidthWebRTC/**/*'
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  
  s.dependency 'JSONRPCWebSockets', '~> 1.0.0'
  s.dependency 'webrtc-swift', '~> 1.0.0'
end





  

#
# Be sure to run `pod lib lint bandwidth-webrtc-swift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'bandwidth-webrtc-swift'
  s.version          = '1.0.0'
  s.summary          = 'A short description of bandwidth-webrtc-swift.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/artemHrebinikChisw/bandwidth-webrtc-swift'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'artemHrebinikChisw' => '75477796+artemHrebinikChisw@users.noreply.github.com' }
  s.source           = { :git => 'https://github.com/artemHrebinikChisw/bandwidth-webrtc-swift.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'
  s.source_files = 'Sources/BandwidthWebRTC/**/*'
end





  

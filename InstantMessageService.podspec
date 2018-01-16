#
# Be sure to run `pod lib lint InstantMessageService.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
s.name             = 'InstantMessageService'
s.version          = '0.2.4'
s.summary          = 'A Simple WebRtc Application For Ios "1111 Find Jobs".'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

s.description      = <<-DESC
1111人力銀行專為求職、打工者量身打造，提供最新徵才職缺，全方位滿足就業、打工、兼差、求職、轉職需求。幫你隨時掌握每1則工作資訊機會！
DESC

s.homepage         = 'https://github.com/wujackson2007/InstantMessageService'
# s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
s.license          = { :type => 'MIT', :file => 'LICENSE' }
s.author           = { 'wujackson2007' => 'wujackson2007' }
s.source           = { :git => 'https://github.com/wujackson2007/InstantMessageService.git', :tag => s.version.to_s }
# s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
s.platform         = :ios, "9.0"
s.ios.deployment_target = '9.0'

s.source_files = 'InstantMessageService/Classes/**/*'

# s.resource_bundles = {
#   'InstantMessageService' => ['InstantMessageService/Assets/*.png']
# }

# s.public_header_files = 'Pod/Classes/**/*.h'
# s.frameworks = 'UIKit', 'MapKit'
s.dependency 'SignalR-ObjC', '~> 2.0'
s.dependency 'GoogleWebRTC', '~> 1.1'
#s.ios.vendored_frameworks = 'sdk/*.framework'

end


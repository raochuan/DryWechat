#
# Be sure to run `pod lib lint DryWechat.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#
# 提交仓库:
# pod spec lint DryWechat.podspec --allow-warnings
# pod trunk push DryWechat.podspec --allow-warnings
#

Pod::Spec.new do |s|
  
  # Git
  s.name        = 'DryWechat'
  s.version     = '0.0.1'
  s.summary     = 'DryWechat'
  s.homepage    = 'https://github.com/duanruiying/DryWechat'
  s.license     = { :type => 'MIT', :file => 'LICENSE' }
  s.author      = { 'duanruiying' => '2237840768@qq.com' }
  s.source      = { :git => 'https://github.com/duanruiying/DryWechat.git', :tag => s.version.to_s }
  s.description = <<-DESC
  TODO: iOS微信功能简化(登录、支付、分享、打开小程序).
  DESC
  
  # User
  s.swift_version         = '5'
  s.ios.deployment_target = '9.0'
  s.requires_arc          = true
  s.user_target_xcconfig  = {'OTHER_LDFLAGS' => ['-w', '-ObjC']}
  
  # Pod
  s.static_framework      = true
  s.pod_target_xcconfig   = {'OTHER_LDFLAGS' => ['-w']}
  
  # Code
  s.source_files          = 'DryWechat/Classes/Code/**/*'
  s.public_header_files   = 'DryWechat/Classes/Code/Public/**/*.h'
  
  # System
  s.libraries  = 'z', 'sqlite3.0', 'c++'
  s.frameworks = 'UIKit', 'Foundation', 'SystemConfiguration', 'Security', 'CoreTelephony', 'CFNetwork', 'CoreGraphics'
  
  # ThirdParty
  #s.vendored_libraries  = ''
  #s.vendored_frameworks = ''
  s.dependency 'WechatOpenSDK'
  
end

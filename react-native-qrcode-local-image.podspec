Pod::Spec.new do |spec|
  spec.name         = 'react-native-qrcode-local-image'
  spec.version      = '1.0.4'
  spec.license      = { :type => 'MIT' }
  spec.homepage     = 'https://github.com/remobile/react-native-qrcode-local-image'
  spec.authors      = { 'YunJiang Fang' => '42550564@qq.com' }
  spec.source       = { :git => 'https://github.com/remobile/react-native-qrcode-local-image.git' }
  spec.source_files = 'ios/RCTQRCodeLocalImage/*.{h,m}'
  spec.summary = "this is a paaaackage"

  spec.dependency 'React'
end
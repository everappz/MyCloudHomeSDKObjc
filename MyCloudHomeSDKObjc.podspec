Pod::Spec.new do |s|
  s.name         = 'MyCloudHomeSDKObjc'
  s.version      = '1.0.1'
  s.summary      = 'A pleasant wrapper around the My Cloud Home API.'
  s.homepage     = 'https://github.com/leshkoapps/MyCloudHomeSDKObjc.git'
  s.author       = { 'Everappz' => 'https://everapz.com' }
  s.source       = { :git => 'https://github.com/leshkoapps/MyCloudHomeSDKObjc.git', :tag => s.version.to_s }
  s.requires_arc = true
  s.platform     = :ios, '9.0'
  s.source_files = 'SDK/*.{h,m}'
  s.framework    = 'Foundation', 'WebKit'
  s.dependency 'ISO8601DateFormatter'
  s.dependency 'AppAuth'
end
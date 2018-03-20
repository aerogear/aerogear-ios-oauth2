Pod::Spec.new do |s|
  s.name         = "TDConnectIosSdk"
  s.version      = "1.4.0"
  s.summary      = "OAuth2 client library based on aerogear-ios-http"
  s.homepage     = "https://github.com/telenordigital/connect-ios-sdk"
  s.license      = 'Apache License, Version 2.0'
  s.author       = "Telenor Digital"
  s.source       = { :git => 'https://github.com/telenordigital/connect-ios-sdk.git', :tag => s.version }
  s.platform     = :ios, 9.0
  s.source_files = 'TDConnectIosSdk/*.{swift,h,m}', 'TDConnectIosSdk/libs/curl/include/curl/*.{h}'
  s.vendored_libraries = 'TDConnectIosSdk/libs/curl/lib/libcurl.a'
  s.libraries    = 'z'
  s.requires_arc = true
  s.framework = 'Security'
  s.dependency 'AeroGearHttp'
  s.dependency 'JSONWebToken'
end

Pod::Spec.new do |s|
  s.name         = "TDConnectIosSdk"
  s.version      = "0.8.0"
  s.summary      = "OAuth2 client library based on aerogear-ios-http"
  s.homepage     = "https://github.com/telenordigital/aerogear-ios-oauth2"
  s.license      = 'Apache License, Version 2.0'
  s.author       = "Telenor Digital"
  s.source       = { :git => 'https://github.com/telenordigital/aerogear-ios-oauth2.git', :tag => s.version }
  s.platform     = :ios, 8.0
  s.source_files = 'TDConnectIosSdk/*.{swift}'
  s.requires_arc = true
  s.framework = 'Security'
  s.dependency 'AeroGearHttp'
  s.dependency 'JSONWebToken'
end

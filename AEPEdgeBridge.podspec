Pod::Spec.new do |s|
  s.name             = "AEPEdgeBridge"
  s.version          = "1.0.0-beta"
  s.summary          = "Experience Platform Edge Bridge extension for Adobe Experience Platform Mobile SDK. Written and maintained by Adobe."

  s.description      = <<-DESC
                       The Experience Platform Edge Bridge extension enables forwarding track data to the Adobe Experience Edge from a mobile device using the v5 Adobe Experience Platform SDK.
                       DESC

  s.homepage         = "https://github.com/adobe/aepsdk-edgebridge-ios.git"
  s.license          = { :type => "Apache License, Version 2.0", :file => "LICENSE" }
  s.author           = "Adobe Experience Platform SDK Team"
  s.source           = { :git => "https://github.com/adobe/aepsdk-edgebridge-ios.git", :tag => s.version.to_s }
  s.ios.deployment_target = '10.0'
  s.swift_version = '5.1'

  s.pod_target_xcconfig = { 'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES' }
  s.dependency 'AEPCore', '>= 3.5.0'
  s.dependency 'AEPEdge', '>= 1.4.0'

  s.source_files = 'Sources/**/*.swift'
end

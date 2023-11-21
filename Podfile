# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'

# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!

workspace 'AEPEdgeBridge'
project 'AEPEdgeBridge.xcodeproj'

pod 'SwiftLint', '0.52.0'

target 'AEPEdgeBridge' do
  pod 'AEPCore'
end

target 'UnitTests' do
  pod 'AEPCore'
  pod 'AEPTestUtils', :git => 'https://github.com/adobe/aepsdk-testutils-ios.git', :branch => 'path-options-refactor2'
end

target 'FunctionalTests' do
  pod 'AEPCore'
  pod 'AEPEdge'
  pod 'AEPEdgeIdentity'
  pod 'AEPTestUtils', :git => 'https://github.com/adobe/aepsdk-testutils-ios.git', :branch => 'path-options-refactor2'
end

target 'TestAppSwiftUI' do
  pod 'AEPCore'
  pod 'AEPLifecycle'
  pod 'AEPEdge'
  pod 'AEPEdgeIdentity'
  pod 'AEPAssurance'
end

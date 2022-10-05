# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!

workspace 'AEPEdgeBridge'
project 'AEPEdgeBridge.xcodeproj'

pod 'SwiftLint', '0.44.0'

target 'AEPEdgeBridge' do
  pod 'AEPCore'
end

target 'UnitTests' do
  pod 'AEPCore'
end

target 'FunctionalTests' do
  pod 'AEPCore'
  pod 'AEPEdge'
  pod 'AEPEdgeIdentity'
end

target 'TestAppSwiftUI' do
  pod 'AEPCore'
  pod 'AEPLifecycle'
  pod 'AEPEdge'
  pod 'AEPEdgeIdentity'
  pod 'AEPAssurance'
end

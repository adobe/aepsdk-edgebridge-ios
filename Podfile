# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'

# Comment the next line if you don't want to use dynamic frameworks
use_frameworks!

workspace 'AEPEdgeBridge'
project 'AEPEdgeBridge.xcodeproj'

pod 'SwiftLint', '0.52.0'

def core_pods
  pod 'AEPCore'
end

def edge_pods
  pod 'AEPEdge'
  pod 'AEPEdgeIdentity'
end

target 'AEPEdgeBridge' do
  core_pods
end

target 'UnitTests' do
  core_pods
  pod 'AEPTestUtils', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :tag => 'testutils-5.2.2'
end

target 'FunctionalTests' do
  core_pods
  edge_pods
  pod 'AEPTestUtils', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :tag => 'testutils-5.2.2'
end

target 'TestAppSwiftUI' do
  core_pods
  edge_pods
  pod 'AEPLifecycle'
  pod 'AEPAssurance'
end

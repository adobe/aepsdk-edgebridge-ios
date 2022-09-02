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

target 'TutorialAppStart' do
  pod 'AEPAnalytics'
  pod 'AEPCore'
  pod 'AEPIdentity'
  pod 'AEPServices'
end

target 'TutorialAppFinal' do
  pod 'AEPAnalytics'
  pod 'AEPAssurance'
  pod 'AEPCore'
  pod 'AEPEdge'
  pod 'AEPEdgeConsent'
  pod 'AEPEdgeIdentity'
  pod 'AEPIdentity'
  pod 'AEPLifecycle'
  pod 'AEPServices'
end

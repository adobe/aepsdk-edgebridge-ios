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

target 'TestAppiOS' do
  core_pods
  edge_pods
  pod 'AEPLifecycle'
  pod 'AEPAssurance'
end

target 'TestApptvOS' do
  core_pods
  edge_pods
  pod 'AEPLifecycle'
end

post_install do |pi|
  pi.pods_project.targets.each do |t|
    t.build_configurations.each do |bc|
        bc.build_settings['TVOS_DEPLOYMENT_TARGET'] = '12.0'
        bc.build_settings['SUPPORTED_PLATFORMS'] = 'iphoneos iphonesimulator appletvos appletvsimulator'
        bc.build_settings['TARGETED_DEVICE_FAMILY'] = "1,2,3"
    end
  end
end

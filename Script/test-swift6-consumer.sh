#!/bin/bash

set -e # Any subsequent(*) commands which fail will cause the shell script to exit immediately

# Builds a minimal Swift 6 consumer of AEPEdgeBridge. The consumer target is compiled
# in Swift 6 language mode and registers EdgeBridge, then sends the Analytics track
# calls that EdgeBridge forwards, all from @MainActor code. This catches any change
# that would stop Swift 6 apps from compiling against AEPEdgeBridge.

PROJECT_NAME=Swift6Consumer

# Clean up.
rm -rf $PROJECT_NAME

mkdir -p $PROJECT_NAME && cd $PROJECT_NAME

# Create the package.
swift package init

# Create the Package.swift. The consumer target is compiled in Swift 6 language
# mode; dependencies keep their own declared language modes.
echo "// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
let package = Package(
    name: \"Swift6Consumer\",
    defaultLocalization: \"en-US\",
    platforms: [
        .iOS(.v15), .tvOS(.v15)
    ],
    products: [
        .library(
            name: \"Swift6Consumer\",
            targets: [\"Swift6Consumer\"]
        )
    ],
    dependencies: [
        .package(name: \"AEPCore\", url: \"https://github.com/adobe/aepsdk-core-ios.git\", .branch(\"main\")),
        .package(name: \"AEPEdgeBridge\", path: \"../\")
    ],
    targets: [
        .target(
            name: \"Swift6Consumer\",
            dependencies: [
                .product(name: \"AEPCore\", package: \"AEPCore\"),
                .product(name: \"AEPEdgeBridge\", package: \"AEPEdgeBridge\"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ])
    ]
)
" >Package.swift

# Replace the generated source with a @MainActor consumer that registers EdgeBridge
# and sends the track calls it forwards to the Edge Network.
rm -rf Sources/Swift6Consumer
mkdir -p Sources/Swift6Consumer
echo "import AEPCore
import AEPEdgeBridge
import Foundation

@MainActor
final class Swift6Consumer {
    var registered = false
    var edgeBridgeVersion = \"\"

    func exercise() {
        edgeBridgeVersion = EdgeBridge.extensionVersion

        // Plain closure from @MainActor code. Only Sendable values cross back to the main actor.
        MobileCore.registerExtensions([EdgeBridge.self]) {
            Task { @MainActor in
                self.registered = true
            }
        }

        MobileCore.track(action: \"purchase\", data: [\"&&events\": \"event5,purchase\", \"myapp.promotion\": \"a0138\"])
        MobileCore.track(state: \"products/189025/runningshoes/12345\", data: [\"myapp.category\": \"189025\"])
    }
}
" >Sources/Swift6Consumer/Swift6Consumer.swift

swift package update
swift package resolve

# This is necessary to avoid internal PIF error
swift package dump-pif > /dev/null
(xcodebuild clean -scheme Swift6Consumer -destination 'generic/platform=iOS' > /dev/null) || :

# Build for generic iOS device in Swift 6 language mode
echo '############# Build Swift 6 consumer for generic iOS device ###############'
xcodebuild build -scheme Swift6Consumer -destination 'generic/platform=iOS'

# Build for generic tvOS device in Swift 6 language mode
echo '############# Build Swift 6 consumer for generic tvOS device ###############'
xcodebuild build -scheme Swift6Consumer -destination 'generic/platform=tvOS'

# Clean up.
cd ../
rm -rf $PROJECT_NAME

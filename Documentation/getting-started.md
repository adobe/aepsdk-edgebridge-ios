# Adobe Experience Platform Edge Bridge for iOS
The AEP Edge Bridge mobile extension provides seamless routing of data to the Adobe Experience Platform Edge Network for existing SDK implementations. For applications which already make use of the [MobileCore.trackAction](https://aep-sdks.gitbook.io/docs/foundation-extensions/mobile-core/mobile-core-api-reference#trackaction) and/or [MobileCore.trackState](https://aep-sdks.gitbook.io/docs/foundation-extensions/mobile-core/mobile-core-api-reference#trackstate) APIs to send data to Adobe Analytics, this extension will automatically route those API calls to the Edge Network, making the data available for mapping to a user's XDM schema using the [Data Prep for Data Collection](https://experienceleague.adobe.com/docs/experience-platform/data-prep/home.html).

> **Note**
> It is recommended to send well formatted XDM data directly from an application using the [Edge.sendEvent](https://aep-sdks.gitbook.io/docs/foundation-extensions/experience-platform-extension/edge-network-api-reference#sendevent) API instead of using the `trackState` and `trackAction` APIs with the Edge Bridge extension. However, in cases where it is not feasible to refactor the application, the Edge Bridge extension is available as a drop-in solution to send `trackState` and `trackAction` data to the Edge Network.
>
>  For new implementations of the SDK, it it highly recommended to send XDM data directly using the [Edge.sendEvent](https://aep-sdks.gitbook.io/docs/foundation-extensions/experience-platform-extension/edge-network-api-reference#sendevent) API.
>

## Before starting

### Install AEP Edge extension

The Adobe Experience Platform Edge Bridge extension requires the Adobe Experience Platform Edge Network extension in order to operate. As a first step install and configure the [AEP Edge](https://github.com/adobe/aepsdk-edge-ios#readme) extension, then continue with the steps below.

## Add the AEP Edge Bridge extension to an app

### Download and import the Edge Bridge extension

> **Note**
> The AEP Edge Bridge extension does not have a corresponding extension in the Data Collection UI. No changes to a Data Collection mobile property are required to use the AEP Edge Bridge extension.

### Install extension
These are currently the supported installation options:

#### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

```ruby
# Podfile
use_frameworks!

# for app development, include the following pod
target 'YOUR_TARGET_NAME' do
  pod 'AEPCore'
  pod 'AEPEdge'
  pod 'AEPEdgeBridge'
  pod 'AEPEdgeIdentity'
end
```

Replace `YOUR_TARGET_NAME` and then, in the `Podfile` directory, type:

```ruby
$ pod install
```

#### [Swift Package Manager](https://github.com/apple/swift-package-manager)

To add the AEPEdgeBridge Package to your application, from the Xcode menu select:

`File > Swift Packages > Add Package Dependency...`

Enter the URL for the AEPEdgeBridge package repository: `https://github.com/adobe/aepsdk-edgebridge-ios.git`.

When prompted, input a specific version or a range of version for Version rule.

Alternatively, if your project has a `Package.swift` file, you can add AEPEdgeBridge directly to your dependencies:

```
dependencies: [
	.package(url: "https://github.com/adobe/aepsdk-core-ios.git", .upToNextMajor(from: "3.0.0")),
	.package(url: "https://github.com/adobe/aepsdk-edge-ios.git", .upToNextMajor(from: "1.0.0")),
	.package(url: "https://github.com/adobe/aepsdk-edgebridge-ios.git", .upToNextMajor(from: "1.0.0")),
	.package(url: "https://github.com/adobe/aepsdk-edgeidentity-ios.git", .upToNextMajor(from: "1.0.0")),
],
targets: [
   	.target(name: "YourTarget",
    		dependencies: ["AEPCore",
                       "AEPEdge",
                       "AEPEdgeBridge",
                       "AEPEdgeIdentity"],
          	path: "your/path")
]
```

#### Binaries

To generate an `AEPEdgeBridge.xcframework`, run the following command:

```ruby
$ make archive
```

This generates the xcframework under the `build` folder. Drag and drop all the `.xcframeworks` to your app target in Xcode.

Repeat these steps for each of the required depdendencies:
- [AEPCore](https://github.com/adobe/aepsdk-core-ios#binaries)
- [AEPEdge](https://github.com/adobe/aepsdk-edge-ios#binaries)
- [AEPEdgeIdentity](https://github.com/adobe/aepsdk-edgeidentity-ios#binaries)

### Import and register extension

#### Swift

```swift
// AppDelegate.swift

import AEPCore
import AEPEdge
import AEPEdgeBridge
import AEPEdgeIdentity

...
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    MobileCore.registerExtensions([Identity.self,
                                   Edge.self,
                                   EdgeBridge.self], {
    MobileCore.configureWith(appId: "yourEnvironmentFileID")
  })
  ...
}
```

#### Objective-C

```objectivec
// AppDelegate.h
@import AEPCore;
@import AEPEdge;
@import AEPEdgeBridge;
@import AEPEdgeIdentity;
```

```objectivec
// AppDelegate.m
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [AEPMobileCore registerExtensions:@[AEPMobileEdgeIdentity.class,
                                        AEPMobileEdge.class,
                                        AEPMobileEdgeBridge.class]
                   completion:^{
    ...
  }];
  [AEPMobileCore configureWithAppId: @"yourEnvironmentFileID"];
  ...
}
```

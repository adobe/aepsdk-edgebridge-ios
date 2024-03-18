# Adobe Experience Platform Edge Bridge

[![CocoaPods](https://img.shields.io/github/v/release/adobe/aepsdk-edgebridge-ios?label=CocoaPods&logo=apple&logoColor=white&color=orange)](https://cocoapods.org/pods/AEPEdgeBridge)
[![SPM](https://img.shields.io/github/v/release/adobe/aepsdk-edgebridge-ios?label=SPM&logo=apple&logoColor=white&color=orange)](https://github.com/adobe/aepsdk-edgebridge-ios/releases)
[![CircleCI](https://img.shields.io/circleci/project/github/adobe/aepsdk-edgebridge-ios/main.svg?label=Build&logo=circleci)](https://circleci.com/gh/adobe/workflows/aepsdk-edgebridge-ios)
[![Code Coverage](https://img.shields.io/codecov/c/github/adobe/aepsdk-edgebridge-ios/main.svg?label=Coverage&logo=codecov)](https://codecov.io/gh/adobe/aepsdk-edgebridge-ios/branch/main)

## About this project

The AEP Edge Bridge mobile extension enables forwarding of Analytics track events to Adobe Edge Network when using the [Adobe Experience Platform SDK](https://developer.adobe.com/client-sdks/documentation/) and the Edge Network extension. The configured Data Collection datastream for the mobile application can define a mapping of the track event's contextdata to an XDM schema using [Data Prep for Data Collection](https://experienceleague.adobe.com/docs/platform-learn/data-collection/edge-network/data-prep.html).

## Requirements
- Xcode 15 (or newer)
- Swift 5.1 (or newer)

## Add Edge Bridge extension to an application

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

`File > Add Packages...`

> **Note** 
> The menu options may vary depending on the version of Xcode being used.

Enter the URL for the AEPEdgeBridge package repository: `https://github.com/adobe/aepsdk-edgebridge-ios.git`.

When prompted, input a specific version or a range of versions for Version rule.

Alternatively, if your project has a `Package.swift` file, you can add AEPEdgeBridge directly to your dependencies:

```
dependencies: [
    .package(url: "https://github.com/adobe/aepsdk-edgebridge-ios.git", .upToNextMajor(from: "5.0.0"))
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

## Development

The first time you clone or download the project, you should run the following from the root directory to setup the environment:

~~~
make pod-install
~~~

Subsequently, you can make sure your environment is updated by running the following:

~~~
make pod-update
~~~

#### Open the Xcode workspace
Open the workspace in Xcode by running the following command from the root directory of the repository:

~~~
make open
~~~

#### Command line integration

You can run all the test suites from command line:

~~~
make test
~~~

## Documentation
Find further documentation in the [Documentation](./Documentation/) folder.

## Related Projects

| Project                                                      | Description                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [AEPCore Extensions](https://github.com/adobe/aepsdk-core-ios) | The AEPCore and AEPServices represent the foundation of the Adobe Experience Platform SDK. |
| [AEPEdge Extension](https://github.com/adobe/aepsdk-edge-ios) | The AEPEdge extension allows you to send data to the Adobe Experience Platform (AEP) from a mobile application. |
| [AEP SDK Sample App for iOS](https://github.com/adobe/aepsdk-sample-app-ios) | Contains iOS sample apps for the AEP SDK. Apps are provided for both Objective-C and Swift implementations. |
| [AEP SDK Sample App for Android](https://github.com/adobe/aepsdk-sample-app-android) | Contains Android sample app for the AEP SDK.                 |
## Contributing

Contributions are welcomed! Read the [Contributing Guide](./.github/CONTRIBUTING.md) for more information.

## Licensing

This project is licensed under the Apache V2 License. See [LICENSE](LICENSE) for more information.

## Security policy

See the [SECURITY POLICY](SECURITY.md) for more details.

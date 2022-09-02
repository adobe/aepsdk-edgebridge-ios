# Adobe Experience Platform Edge Bridge

## BETA

AEPEdgeBridge is currently in beta. Use of this code is by invitation only and not otherwise supported by Adobe. Please contact your Adobe Customer Success Manager to learn more.

By using the Beta, you hereby acknowledge that the Beta is provided "as is" without warranty of any kind. Adobe shall have no obligation to maintain, correct, update, change, modify or otherwise support the Beta. You are advised to use caution and not to rely in any way on the correct functioning or performance of such Beta and/or accompanying materials.

## About this project

The AEP Edge Bridge mobile extension enables forwarding of Analytics track events to Adobe Edge Network when using the [Adobe Experience Platform SDK](https://aep-sdks.gitbook.io/docs/) and the Edge Network extension. The configured Data Collection datastream for the mobile application can define a mapping of the track event's contextdata to an XDM schema using [Data Prep for Data Collection](https://experienceleague.adobe.com/docs/platform-learn/data-collection/edge-network/data-prep.html).

## Requirements
- Xcode 11.0 (or newer)
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

To add the AEPEdgeBridge Package to your application, from the Xcode 13.x menu select:

`File > Add Packages...`

> **Note** 
> the menu options may vary depending on the version of Xcode being used.

Enter the URL for the AEPEdgeBridge package repository: `https://github.com/adobe/aepsdk-edgebridge-ios.git`.

When prompted, input a specific version or a range of versions for Version rule.

Alternatively, if your project has a `Package.swift` file, you can add AEPEdgeBridge directly to your dependencies:

```
dependencies: [
    .package(url: "https://github.com/adobe/aepsdk-edgebridge-ios.git", .upToNextMajor(from: "1.0.0"))
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

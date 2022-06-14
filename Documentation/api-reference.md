# Adobe Experience Platform Edge Bridge for iOS

## API Reference

| APIs                                           		|
| ---------------------------------------------- |
| [extensionVersion](#extensionversion)	|
| [registerExtension](#registerextension)	|

------

### extensionVersion
Returns the version of the Edge Bridge extension.

#### Swift

##### Syntax
```swift
static var extensionVersion: String
```

##### Examples
```swift
let extensionVersion = EdgeBridge.extensionVersion
```

#### Objective-C

##### Syntax
```objectivec
+ (nonnull NSString*) extensionVersion;
```

##### Examples
```objectivec
NSString *extensionVersion = [AEPMobileEdgeBridge extensionVersion];
```

------

### registerExtension
In iOS, the registration occurs by passing the Edge Bridge extension to the `MobileCore.registerExtension` API.

#### Swift

##### Syntax
```swift
static func registerExtensions(_ extensions: [NSObject.Type], 
                               _ completion: (() -> Void)? = nil)
```

##### Examples
```swift
import AEPEdgeBridge

...
MobileCore.registerExtensions([EdgeBridge.self])
```

#### Objective-C

##### Syntax
```objectivec
+ (void) registerExtensions: (NSArray<Class*>* _Nonnull) extensions 
                 completion: (void (^ _Nullable)(void)) completion;
```

##### Examples
```objectivec
@import AEPEdgeIdentity;

...
[AEPMobileCore registerExtensions:@[AEPMobileEdgeBridge.class] completion:nil];
```

------
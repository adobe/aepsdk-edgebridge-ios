# AEP Analytics & Edge Bridge
## Overview
This hands-on tutorial provides end-to-end instructions for Mobile SDK customers on how  Edge Bridge can help easily migrate from AEPAnalytics to AEP.

There are other beginning states the customer can be in like using ACP Analytics, v4 extension, etc. These usages can potentially be migrated to AEP and from there, this tutorial can be applied afterwards. However, this should be determined on a case-by-case basis, as for example in the v4 extension case, it may be more effective to simply implement AEP extensions itself without the need for Edge Bridge migration path.

Tutorial setup:

Initial test app that is based on prerequisites (implements Analytics)
Final test app after all the tutorial steps have been implemented (implements EdgeBridge)

Tutorial steps:

      0. Prerequisites (set up Analytics report suite, mobile property, Assurance). List out required permissions for this tutorial: Analytics, Schema creation, Data Collection (Launch tags), Datastream view and edit, Assurance.

## Data Collection config instructions
Create XDM schema   
Configure Datastream, enable Analytics - 2 paths:   
    - same rsid(s) as in Analytics extension (if using Analytics + EdgeBridge this will cause double counting).  
    - different rsid(s) if the customer wants to start new or run the migration in a comparison mode (Analytics + EdgeBridge side by side).  

Install Edge Network & Edge Identity in Launch - Edge Bridge does not have a card here  
Analytics should remain installed in Launch for production app versions.  
Publish the changes  

## Client-side implementation
### 1. Install Edge Bridge using dependency manager
To install EdgeBridge, use the currently the supported installation options:
### iOS
#### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

```ruby
# Podfile
use_frameworks!

# For app development, include all the following pods
target 'YOUR_TARGET_NAME' do
  pod 'AEPAnalytics'
  pod 'AEPCore'
  pod 'AEPIdentity'
  pod 'AEPLifecycle'  
  pod 'AEPServices'
  
  pod 'AEPEdgeBridge'

  pod 'AEPAssurance', '~> 3.0.0'
end
```

#### [Swift Package Manager](https://github.com/apple/swift-package-manager)

To add the AEPEdgeBridge Package to your application, from the Xcode menu select:

`File > Swift Packages > Add Package Dependency...`

Enter the URL for the AEPEdgeIdentity package repository: `https://github.com/adobe/aepsdk-edgebridge-ios.git`. 

When prompted, input a specific version or a range of version for Version rule.

Alternatively, if your project has a `Package.swift` file, you can add AEPEdgeBridge directly to your dependencies:

```
dependencies: [
	.package(url: "https://github.com/adobe/aepsdk-edgebridge-ios.git", .upToNextMajor(from: "1.0.0"))
],
targets: [
   	.target(name: "YourTarget",
    		dependencies: ["AEPEdgeBridge"],
          	path: "your/path")
]
```

### 2. Imports and extension registration diff  
In your AppDelegate file, import the newly installed extension and register it with `MobileCore`:

```swift
import UIKit
import AEPCore
import AEPIdentity
import AEPAnalytics
import AEPAssurance
import AEPLifecycle
import AEPServices
import AEPEdgeBridge // <-- Newly added

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        MobileCore.setLogLevel(.trace)
        MobileCore.registerExtensions([
            Identity.self, 
            Analytics.self, 
            Lifecycle.self, 
            Assurance.self
            EdgeBridge.self // <-- Newly added
        ], {
            // Use the App ID assigned to this application via Adobe Data Collection UI
            MobileCore.configureWith(appId: self.ENVIRONMENT_FILE_ID)
        })
        return true
    }
```

### 3. Run app   
In Xcode, select the app target you want to run, and the destination device to run it on (either simulator or physical device). Then press the play button.

You should see your application running on the device you selected, with logs being displayed in the console in Xcode. 

> **Note**
> If the debug console area is not shown by default, activate it by selecting:  
> View -> Debug Area -> Show Debug Area

### 4. TrackAction/TrackState implementation examples   
With Edge Bridge extension successfully installed and registered, you can make  `trackAction` and `trackState` calls, which will be captured by Edge Bridge extension and sent to the Edge network.

#### Swift
```swift
let actionData: [String: Any] = [
    "product.id": "12345", 
    "product.add.event": "1", 
    "product.name": "wide_brim_sunhat", 
    "product.units": "1"
]
MobileCore.track(action: "add_to_cart", data: actionData)

let stateData: [String: Any] = [
    "product.name": "wide_brim_sunhat", 
    "product.id": "12345", 
    "product.view.event": "1"
]
MobileCore.track(state: "hats/sunhat/wide_brim_sunhat_id12345", data: stateData)
```

## Initial validation with Assurance
### 1. Set up the Assurance session  
1. In the browser, navigate to [Assurance](https://experience.adobe.com/griffon) and login using your Adobe ID credentials.
2. Create a new session (or use an existing one if available) 
    - Click `Create Session` in the top right.
![Create session in Assurance](../assets/edge-bridge-tutorial/assurance-create-session.jpg)
    - In the `Create New Session` dialog, review instructions, and proceed by selecting `Start`  
<img src="../assets/edge-bridge-tutorial/assurance-create-session-1.png" alt="Creating a new session in Assurance step 1" width="400"/>

    - Enter a name to identify the session (can be any desired name) 
    - Use Base URL value: `aepedgebridge://`  
<img src="../assets/edge-bridge-tutorial/assurance-create-session-2.png" alt="Creating a new session in Assurance step 2" width="400"/>

> **Note**  
> The Base URL is the root definition used to launch your app from a URL (deep linking). A session URL is generated by which you may initiate the Assurance session. An example value might look like: `myapp://default`  
>
> Note that proper base URL configuration is required for Assurance QR code app launching to function.
>
>If you do not know the URL or don't want to use it at this time, enter a placeholder URL like `test://`. Assurance Session URL connection is still possible without app side URL configuration.
>  
> In Xcode the app URL can be configured using these steps:
> 1. Select the project in the navigator.
> 2. Select the app target in the `Targets` section, in the project configuration window.
> 3. Select the `Info` tab.
> 4. Set the desired deep linking URL.
> ![Xcode deeplink app url config](../assets/edge-bridge-tutorial/xcode-deeplink-app-url-config.jpg)
> Please note that there is still code on the application side that is required for the app to respond to deep links; see the [guide on adding Assurance to your app](https://aep-sdks.gitbook.io/docs/foundation-extensions/adobe-experience-platform-assurance#add-the-aep-assurance-extension-to-your-app). For general implementation recommendations and best practices, see Apple's guide on [Defining a custom URL scheme for your app](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app)

When presented with this window, the new Assurance session is created, and it is now possible to connect the app to your Assurance session.  
<img src="../assets/edge-bridge-tutorial/assurance-create-session-qr.png" alt="Creating a new session in Assurance step 3 - QR code" width="400"/>
<img src="../assets/edge-bridge-tutorial/assurance-create-session-link.png" alt="Creating a new session in Assurance step 3 - Session link" width="400"/>

### 2. Connect to the app   
There are two primary ways to connect an app instance to an Assurance session:
1. QR Code: available with `Scan QR Code` option selected. Only works with physical devices, as it requires a physical device's camera to scan the code. Note that this method requires setup on the application code side to allow for deep linking (see [Set up the Assurance session](#1-set-up-the-assurance-session)).

2. Session Link: available with `Copy Link` option selected. Works with both physical and simulated devices.

To access these connection methods, click `Session Details`:  
<img src="../assets/edge-bridge-tutorial/assurance-session-details-qr.png" alt="Assurance Session Details - QR code" width="400"/>
<img src="../assets/edge-bridge-tutorial/assurance-session-details-link.png" alt="Assurance Session Details - Session link" width="400"/>

Note that it is possible to edit both the `Session Name` and `Base URL`; changes to the `Base URL` value will automatically be reflected in both QR code and session link.

To connect using QR code:
Prerequisites (see [Set up the Assurance session](#1-set-up-the-assurance-session) for details on QR code requirements):
- Running app using physical device with camera that can scan QR codes
- App URL for deep linking is configured
- App code for receiving link and connecting to Assurance is implemented

1. Use physical device's camera to scan the QR code, which when tapped, should trigger a confirmation dialog to open the app.
2. App should open and show the Assurance PIN screen to authenticate the session connection; enter the PIN from the session details and tap `Connect`

To connect using session link:
1. Copy the session link; you can click the icon of a double overlapping box to the right of the link to copy
    - If using a physical device, it may be helpful to have a way to send this link to the device (ex: Airdrop, email, text, etc.)
2. Open the sample app and tap the Assurance button
3. Paste the Assurance session link copied from step 1 and tap `Connect`
    - If using the simulator, it is possible to enable the paste menu by clicking in the text field twice, with a slight pause between clicks.
4. App should open and show the Assurance PIN screen to authenticate the session connection; enter the PIN from the session details and tap `Connect`

Once connected to Assurance, an Adobe Experience Platform icon will appear in the top right corner of the screen with a green dot indicating a connected session. In the web-based Assurance session, there is also an indicator in the top right that shows the number of connected sessions (which in this case should now show a green dot with "1 Client Connected", marked `1` in the screenshot below).

<img src="../assets/edge-bridge-tutorial/simulator-assurance-connection.jpg" alt="Assurance Session Start - iOS simulator" width="400"/>
<img src="../assets/edge-bridge-tutorial/assurance-session-start.jpg" alt="Assurance Session Start - Web UI after connection" width="800"/>  

Observe how in the Assurance session Events view (`2`), there are already events populating as a consequence of the connection of the mobile app to the Assurance session (`3`); the Assurance extension itself emits events about the session connection and subsequently captures these events to display in the web-based session viewer. You can expect Assurance to capture all events processed by the AEP SDK from all other extensions as well.  

### 3. Event transactions view - check for Edge Bridge events  
In order to see Edge Bridge events, in the connected app instance, trigger a `trackAction` and/or `trackState` within the app which the Edge Bridge extension will convert into Edge events. This event will be captured by the Assurance extension and shown in the web session viewer.

```swift
Button("Track Action", action: {
    // Dispatch an Analytics track action event which is handled by the
    // Edge Bridge extension which forwards it to the Edge Network.

    let data: [String: Any] = [
        "product.id": "12345", 
        "product.add.event": "1", 
        "product.name": "wide_brim_sunhat", 
        "product.units": "1"
    ]
    MobileCore.track(action: "add_to_cart", data: data)
}).padding()
```

```swift
Button("Track State", action: {
    // Dispatch an Analytics track state event which is handled by the
    // Edge Bridge extension which forwards it to the Edge Network.

    let data: [String: Any] = [
        "product.name": "wide_brim_sunhat", 
        "product.id": "12345", 
        "product.view.event": "1"
    ]
    MobileCore.track(state: "hats/sunhat/wide_brim_sunhat_id12345", data: data)
}).padding()
```

Click the `AnalyticsTrack` event (`1`) in the events table to see the event details in the right side window; click the `RAW EVENT` dropdown (`2`) in the event details window to see the event data payload. Verify that the `contextdata` matches what was sent by the Analytics `trackAction`/`trackState` API.

<img src="../assets/edge-bridge-tutorial/simulator-track-buttons.jpg" alt="Simulator tracking buttons" width="400"/>
<img src="../assets/edge-bridge-tutorial/assurance-analytics-track-event.jpg" alt="Simulator tracking buttons" width="800"/>

Now click the `Edge Bridge Request` event (`1`) in the events table, and click the `RAW EVENT` dropdown (`2`) in the event details window; notice the slight differences in the payload structure as a result of the `Edge Bridge Request` event conforming to the format of an Edge event.

<img src="../assets/edge-bridge-tutorial/assurance-edge-bridge-track-event.jpg" alt="Simulator tracking buttons" width="800"/>

Notice the differences in event data structure and format between the two types of events: Analytics (left) vs Edge (right) via Edge Bridge extension
The top level EventType is converted from a `generic.track` to `edge` (that is, Analytics generic track event -> Edge event) (`1`). The Edge Bridge extension also populates the standard XDM field for event type (`eventType`) in the event data payload. Also notice that the `contextdata` has moved from directly under `EventData` to under the generic Edge XDM `data` property (`2`).

<img src="../assets/edge-bridge-tutorial/analytics-edge-bridge-conversion.jpg" alt="Comparison of event data between analytics and edge bridge events" width="900"/>

The two new top level properties `xdm` and `data` are standard Edge event properties that are part of a new paradigm for event data organization that enables powerful customizable schema-based data processing. However, because the `contextdata` is not yet paired with an XDM schema, it is not intelligible to the Edge platform. We will solve this issue by mapping the event data to an XDM schema in the next section.

<Image of app button triggering trackAction/trackState + console output? and also corresponding event in assurance event view>

Click the Edge Bridge event to see its details, such as the data payload, event metadata, etc.
<Image of EdgeBridge event, with event selected and event data visible>

## Data prep mapping
Copy data blob from Assurance (hint on copy from logs)  
1. Click the Event which has the data payload you want to map to XDM
2. On the right side details window, click the Raw Event dropdown to see the raw event data
3. Click `Copy Raw Event`

## Add mapping in Data Prep UI  
Click the nine dot menu in the top right and select Data Collection
Select Datastreams in the left-side navigation window
Select the Datastream that should have the mapping from `trackAction`/`trackState` mapped to `XDM` format
Click **Edit Mapping**
Paste the JSON copied from the raw event data from the previous section into the box


## Validation with Assurance
Check mapping feedback in Event transactions view

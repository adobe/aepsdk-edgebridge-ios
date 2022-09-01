# Migrating from Analytics mobile extension to Edge Network using the EdgeBridge extension

## Table of Contents
- [Migrating from Analytics mobile extension to Edge Network using the EdgeBridge extension](#migrating-from-analytics-mobile-extension-to-edge-network-using-the-edgebridge-extension)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Data Collection config instructions](#data-collection-config-instructions)
  - [Prerequisites](#prerequisites)
    - [Environment](#environment)
  - [Client-side implementation](#client-side-implementation)
    - [1. Install Edge Bridge using dependency manager (CocoaPods)](#1-install-edge-bridge-using-dependency-manager-cocoapods)
    - [Swift Package Manager](#swift-package-manager)
    - [2. Imports and extension registration diff](#2-imports-and-extension-registration-diff)
    - [3. Run app](#3-run-app)
    - [4. TrackAction/TrackState implementation examples](#4-trackactiontrackstate-implementation-examples)
      - [Swift](#swift)
  - [Initial validation with Assurance](#initial-validation-with-assurance)
    - [1. Set up the Assurance session](#1-set-up-the-assurance-session)
    - [2. Connect to the app](#2-connect-to-the-app)
    - [3. Event transactions view - check for Edge Bridge events](#3-event-transactions-view---check-for-edge-bridge-events)
  - [Data prep mapping](#data-prep-mapping)
    - [Prerequisites](#prerequisites-1)
    - [1. Create a schema](#1-create-a-schema)
    - [2. Create a datastream](#2-create-a-datastream)
  - [Validation with Assurance](#validation-with-assurance)

## Overview
This hands-on tutorial provides end-to-end instructions on how to migrate to Edge Network from Analytics to EdgeBridge mobile extension.

There are other beginning states the customer can be in like using ACP Analytics, v4 extension, etc. These usages can potentially be migrated to AEP and from there, this tutorial can be applied afterwards. However, this should be determined on a case-by-case basis, as for example in the v4 extension case, it may be more effective to simply implement AEP extensions itself without the need for Edge Bridge migration path.

```mermaid
graph LR;
    step1(Analytics ready app) --> step2(Add Edge and Edge Bridge extensions\ntest) --> step3(Add Assurance) --> step4(Map data to XDM) -> step5(Final app);
```

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

## Prerequisites
- A timestamp enabled report suite is configured for mobile data collection.
- A tag (also known as mobile property) is configured in Data Collection UI which has Adobe Analytics extension installed and configured.
- AEPAnalytics mobile extension is installed and registered in the client-side mobile application.
- `MobileCore.trackAction` and/or `MobileCore.trackState` API(s) are already implemented in the mobile application.

### Environment
- macOS machine with a recent version of Xcode installed

Install Edge Network & Edge Identity in Launch - Edge Bridge does not have a card here  
Analytics should remain installed in Launch for production app versions.  
Publish the changes  

## Client-side implementation
// TODO: refine these steps once tutorial app is complete
### 1. Install Edge Bridge using dependency manager (CocoaPods)
1. Open Podfile
2. Edit Podfile as the following:

```ruby
# Podfile
use_frameworks!

# For app development, include all the following pods
target 'YOUR_TARGET_NAME' do
  pod 'AEPAnalytics'
  pod 'AEPEdgeConsent'
  pod 'AEPCore'
  pod 'AEPEdge'
  pod 'AEPEdgeIdentity'
  pod 'AEPLifecycle'  
  pod 'AEPServices'
  
  pod 'AEPEdgeBridge'

  pod 'AEPAssurance', '~> 3.0.0'
end
```

3. Open a terminal window and while in the project directory, run:
```bash
pod update
```

<details>
  <summary> Using Swift package manager instead? </summary><p>

### Swift Package Manager
This tutorial assumes a project using Cocoapods for package dependency management, but if following along with a project that uses Swift package manager, refer to the [README for instructions on how to add the EdgeBridge package](../../README.md#swift-package-managerhttpsgithubcomappleswift-package-manager).

</p></details>


### 2. Imports and extension registration diff  
// TODO: update this section with just the code snippets to change/replace after updating tutorial app for initial state
// targets etc. should reflect the actual tutorial app

Replace
```swift
import AEPAnalytics
```
With
```swift
import AEPEdgeBridge
```



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
> Note that proper base URL configuration is required for Assurance QR code app launching to function. However, even without setting up deep linking on the application-side, it is still possible to connect to Assurance using the session link.
>
> If you do not know the URL or don't want to use it at this time, enter a placeholder URL like `test://`. 
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

<details>
  <summary> Details on connecting to Assurance </summary><p>

There are two primary ways to connect an app instance to an Assurance session:
1. QR Code: available with `Scan QR Code` option selected. Only works with physical devices, as it requires a physical device's camera to scan the code. Note that this method requires setup on the application code side to allow for deep linking (see [Set up the Assurance session](#1-set-up-the-assurance-session)).

2. Session Link: available with `Copy Link` option selected. Works with both physical and simulated devices.

To access these connection methods, click `Session Details`:  
<img src="../assets/edge-bridge-tutorial/assurance-session-details-qr.png" alt="Assurance Session Details - QR code" width="400"/>
<img src="../assets/edge-bridge-tutorial/assurance-session-details-link.png" alt="Assurance Session Details - Session link" width="400"/>

Note that it is possible to edit both the `Session Name` and `Base URL`; changes to the `Base URL` value will automatically be reflected in both QR code and session link.

</p></details>

To connect using session link:
1. Copy the session link; you can click the icon of a double overlapping box to the right of the link to copy
    - If using a physical device, it may be helpful to have a way to send this link to the device (ex: Airdrop, email, text, etc.)
2. Open the sample app and tap the Assurance button
3. Paste the Assurance session link copied from step 1 and tap `Connect`
    - If using the simulator, it is possible to enable the paste menu by clicking in the text field twice, with a slight pause between clicks.
4. App should open and show the Assurance PIN screen to authenticate the session connection; enter the PIN from the session details and tap `Connect`

<details>
  <summary> Connecting using QR code </summary><p>

To connect using QR code:
Prerequisites (see [Set up the Assurance session](#1-set-up-the-assurance-session) for details on QR code requirements):
- Running app using physical device with camera that can scan QR codes
- App URL for deep linking is configured
- App code for receiving link and connecting to Assurance is implemented

1. Use physical device's camera to scan the QR code, which when tapped, should trigger a confirmation dialog to open the app.
2. App should open and show the Assurance PIN screen to authenticate the session connection; enter the PIN from the session details and tap `Connect`

</p></details>

Once connected to Assurance, an Adobe Experience Platform icon will appear in the top right corner of the screen with a green dot indicating a connected session. In the web-based Assurance session, there is also an indicator in the top right that shows the number of connected sessions (which in this case should now show a green dot with "1 Client Connected", marked `1` in the screenshot below).

<img src="../assets/edge-bridge-tutorial/simulator-assurance-connection.jpg" alt="Assurance Session Start - iOS simulator" width="400"/>
<img src="../assets/edge-bridge-tutorial/assurance-session-start.jpg" alt="Assurance Session Start - Web UI after connection" width="800"/>  

Observe how in the Assurance session Events view (`2`), there are already events populating as a consequence of the connection of the mobile app to the Assurance session (`3`); the Assurance extension itself emits events about the session connection and subsequently captures these events to display in the web-based session viewer. You can expect Assurance to capture all events processed by the AEP SDK from all other extensions as well.  

### 3. Event transactions view - check for Edge Bridge events  
In order to see Edge Bridge events, in the connected app instance, trigger a `trackAction` and/or `trackState` within the app which the Edge Bridge extension will convert into Edge events. This event will be captured by the Assurance extension and shown in the web session viewer.

<img src="../assets/edge-bridge-tutorial/simulator-track-buttons.jpg" alt="Simulator tracking buttons" width="400"/>

Click the `AnalyticsTrack` event (`1`) in the events table to see the event details in the right side window; click the `RAW EVENT` dropdown (`2`) in the event details window to see the event data payload. Verify that the `contextdata` matches what was sent by the Analytics `trackAction`/`trackState` API.

<img src="../assets/edge-bridge-tutorial/assurance-analytics-track-event.jpg" alt="Simulator tracking buttons" width="800"/>

Now click the `Edge Bridge Request` event (`1`) in the events table, and click the `RAW EVENT` dropdown (`2`) in the event details window; notice the slight differences in the payload structure as a result of the `Edge Bridge Request` event conforming to the format of an Edge event.

<img src="../assets/edge-bridge-tutorial/assurance-edge-bridge-track-event.jpg" alt="Simulator tracking buttons" width="800"/>

Notice the differences in event data structure and format between the two types of events: Analytics (left) vs Edge (right) via Edge Bridge extension
The top level EventType is converted from a `generic.track` to `edge` (that is, Analytics generic track event -> Edge event) (`1`). The Edge Bridge extension also populates the standard XDM field for event type (`eventType`) in the event data payload. Also notice that the `contextdata` has moved from directly under `EventData` to under the generic Edge XDM `data` property (`2`).

<img src="../assets/edge-bridge-tutorial/analytics-edge-bridge-conversion.jpg" alt="Comparison of event data between analytics and edge bridge events" width="1100"/>

The two new top level properties `xdm` and `data` are standard Edge event properties that are part of the Edge platform's XDM schema-based system for event data organization that enables powerful, customizable data processing. However, because the `contextdata` is not yet mapped to an XDM schema, it is not in a usable form for the Edge platform. We will solve this issue by mapping the event data to an XDM schema in the next section.

## Data prep mapping

<details>
  <summary> Data Prep background</summary><p>

Data Prep is an Adobe Experience Platform service which maps and transforms data to the [Experience Data Model (XDM)](https://experienceleague.adobe.com/docs/experience-platform/xdm/home.html).  Data Prep is configured from a Platform enabled [datastream](https://experienceleague.adobe.com/docs/experience-platform/edge/datastreams/overview.html) to map source data from the Edge Bridge mobile extension to the Platform Edge Network.

This guide covers how to map data sent from the Edge Bridge within the Data Collection UI.

For a quick overview of the capabilities of Data Prep, watch the following [video](https://experienceleague.adobe.com/docs/platform-learn/data-collection/edge-network/data-prep.html).

> **Note**
> The following documentation provides a comprehensive overview of the Data Prep capabilities:
> - [Data Prep overview](https://experienceleague.adobe.com/docs/experience-platform/data-prep/home.html)
> - [Data Prep mapping functions](https://experienceleague.adobe.com/docs/experience-platform/data-prep/functions.html)
> - [Handling data formats with Data Prep](https://experienceleague.adobe.com/docs/experience-platform/data-prep/data-handling.html)
>

</p></details>

### Prerequisites
Before creating a mapping, we need to create an XDM schema (what we are mapping to) and configure a datastream (where the data will go). In order to send data to the Edge Network, the datastream must be configured with the Adobe Experience Platform service.
### 1. Create a schema  
At a high level, a schema is a definition for the structure of your data; what properties you are expecting, what format they should be in, and checks for the actual values coming in. 

Navigate to the Data Collection UI by clicking the nine-dot menu in the top right (`1`), and selecting `Data Collection` (`2`)  
<img src="../assets/edge-bridge-tutorial/assurance-to-data-collection.png" alt="Going from Assurance to Data Collection" width="1100"/>

Click `Schemas` in the left navigation window  
<img src="../assets/edge-bridge-tutorial/data-collection-tags.png" alt="Going from Assurance to Data Collection" width="1100"/>

In the schemas view, click the `+ Create schema` button in the top right (`1`), then select `XDM ExperienceEvent` (`2`)
<img src="../assets/edge-bridge-tutorial/data-collection-schemas.png" alt="Creating new XDM ExperienceEvent schema" width="1100"/>

Once in the new schema creation view, notice the schema class is `XDM ExperienceEvent` (`1`); schemas adhere to specific class types which just means that they have some predefined properties and behaviors within the Edge platform. In this case, `XDM ExperienceEvent` creates the base properties you see in the `Structure` section that help define some baseline data for each Experience Event. 

(`2`) Give the new schema a name and description to help identify it.
(`3`) Click the `+ Add` button next to the `Field groups` section under `Composition`.

<details>
  <summary> What is a field group?</summary><p>

A schema is made up of building blocks called field groups.

Think of field groups as blueprints for specific groups of data; the data properties describing: the current device in use, products and carts, information about the users themselves, etc. For example, the `Commerce Details` field group has properties for common commerce-related data like product information (SKU, name, quantity), cart state (abandons, product add sources, etc.). This logical grouping helps organize individual data properties into easily understandable sections. They are even reusable! Once you define a field group, you can use it in any schema that has a compatible class (some field groups only make sense with the capabilities of certain schema classes). There are two types of field groups available:

1. Adobe defined - standardized templates of common use-cases and datasets created and updated by Adobe
    - Note that Adobe Experience Platform services implicitly understand standard field groups and can provide additional functionality on top of just reading and writing data. That's why it is strongly recommended that you use standard field groups wherever possible.
2. Custom defined - any field group outside of the Adobe defined ones that users can use to create their own custom collections of data properties  

See the [Field Groups section in the Basics of schema composition](https://experienceleague.adobe.com/docs/experience-platform/xdm/schema/composition.html?lang=en#field-group) for an in depth look at how field groups work in the context of XDM schemas.

</p></details>

<img src="../assets/edge-bridge-tutorial/schema-creation.png" alt="Initial schema creation view" width="1100"/>

In our case, we're going to add three Adobe defined field groups to our schema:  
- AEP Mobile Lifecycle Details
- Adobe Experience Edge Autofilled Environment Details
- Commerce Details

You can use the search box (`1`) to look up the names (`2`) of the three field groups required for this exercise. Note the owner of each of the schemas should be `Adobe` (`3`).
<img src="../assets/edge-bridge-tutorial/schema-field-group-1.png" alt="Add field group to schema" width="1100"/>

<details>
  <summary> Hints for using the Add field group tool</summary><p>

(1) Selected field groups are shown on the right side of the window, where you can quickly see what field groups have been selected so far, and remove individual or all field groups from the current add session.  

(2) Popularity: shows how many organizations are using the field group across Adobe Experience Platform; can potentially be a good place to start in terms of finding which field groups may be the most useful for your needs.

(3) The inspector icon lets you see the field group structure, and the info icon presents a card with the field group name, industry, and description.

(4) The Industry filter selections let you quickly narrow down field groups based on the selected industry; another useful tool to find relevant field groups for your use-case.

<img src="../assets/edge-bridge-tutorial/schema-field-group-2.jpg" alt="Add field group window hints" width="1100"/>  

</p></details>

Verify that all the required field groups are present in the right side info panel (`1`), then click `Add field groups` (`2`). 
<img src="../assets/edge-bridge-tutorial/schema-field-group-3.png" alt="Add required field groups" width="1100"/>  

Verify that the required field groups are present under the `Field groups` section (`1`) and the properties associated with those field groups are present under the `Structure` section (`2`), then click `Save` (`3`).
<img src="../assets/edge-bridge-tutorial/schema-with-field-groups.png" alt="Schema with required field groups" width="1100"/>  

<details>
  <summary> Hints for using the schema creator tool </summary><p>

To quickly see what properties are from a given field group, click the field group under the `Field groups` section (`1`). The properties are highlighted in the `Structure` section (`2`).

<img src="../assets/edge-bridge-tutorial/schema-tool-selection.png" alt="Schema tool selecting a field group example" width="1100"/>  

To see only the properties from a given field group, click the selection box next to the field group (`1`). The properties are filtered to only the selected field group in the `Structure` section (`2`).

<img src="../assets/edge-bridge-tutorial/schema-tool-filtering.png" alt="Schema tool filtering on a field group example" width="1100"/>  

</p></details>

### 2. Create a datastream

<details>
  <summary> What is a datastream? </summary><p>

A datastream is a server-side configuration on Platform Edge Network that controls where data goes. Datastreams ensure that incoming data is routed to Adobe Experience Cloud applications and services (like Analytics) appropriately. For more information, see the [datastreams documentation](https://experienceleague.adobe.com/docs/experience-platform/edge/datastreams/overview.html?lang=en) or this [video](https://experienceleague.adobe.com/docs/platform-learn/data-collection/edge-network/configure-datastreams.html?lang=en).

</p></details>

Click `Datastreams` under `DATA COLLECTION` in the left side navigation panel.

<img src="../assets/edge-bridge-tutorial/datastreams-navigation.png" alt="Datastream in Data Collection Navigation" width="1100"/>  

Click `New Datastream` in the top right.

<img src="../assets/edge-bridge-tutorial/datastreams-main-view.png" alt="Create new datastream" width="1100"/>  

Give the datastream an identifying name and description (`1`), then pick the schema created in the previous section using the dropdown menu (`2`). Then click `Save and Add Mapping` (`3`).

<img src="../assets/edge-bridge-tutorial/datastreams-new-datastream.png" alt="Set datastream values" width="1100"/>  

In order to map the properties from both `trackAction` and `trackState` events in the same datastream, we need to combine their event data properties into a single JSON. For simplicity, the merged data structure has been provided below:

```json
{
  "xdm": {
    "eventType": "analytics.track",
    "timestamp": "2022-08-19T20:55:12.320Z"
  },
  "data": {
    "contextdata": {
      "product.add.event": "1",
      "product.view.event": "1",
      "product.id": "12345",
      "product.name": "wide_brim_sunhat",
      "product.units": "1"
    },
    "action": "add_to_cart",
    "state": "hats/sunhat/wide_brim_sunhat_id12345"
  }
}

```

Copy and paste the JSON data into the datastreams JSON input box (`1`). Verify the uploaded JSON matches what is displayed in the `Preview sample data` section (`2`), then click `Next` (`3`).

<details>
  <summary> Getting the JSON data from Assurance </summary><p>

Navigate back to your Assurance session for the Edge Bridge app and select the `Edge Bridge Request` event (`1`), then open the `RAW EVENT` dropdown and click and drag to select the `ACPExtensionEventData` value as shown, then copy the selected value (right click the highlighted selection and choose `Copy`, or use the copy keyboard shortcut `CMD + C`):

<img src="../assets/edge-bridge-tutorial/assurance-edgebridge-mapping-data.png" alt="Select data from Edge Bridge event" width="1100"/>  

To merge events, you would look for properties under `data` and `contextdata` that are unique between events and include them in the final data payload.

</p></details>

<img src="../assets/edge-bridge-tutorial/datastreams-json-paste.png" alt="Select data from Edge Bridge event" width="1100"/>  

Click the `Add new mapping` button (`1`).

<img src="../assets/edge-bridge-tutorial/datastreams-start-mapping.png" alt="Select data from Edge Bridge event" width="1100"/>  

A new entry for mapping will appear in the window; click the arrow button (`1`) next to the field `Select source field`.

<img src="../assets/edge-bridge-tutorial/datastreams-mapping-1.png" alt="Select data from Edge Bridge event" width="1100"/>  

In the JSON property viewer window, click the dropdown arrows next to `data` (`1`) and `contextdata` (`2`). Then select the first property to map, `product.add.event` (`3`) and click `Select` (`4`).

<img src="../assets/edge-bridge-tutorial/datastreams-select-property.png" alt="Select data from Edge Bridge event" width="1100"/>  

Notice that in the property viewer, you can see the data hierarchy, where `data` is at the top, `contextdata` is one level down, and `product.add.event` is one level below that. This is nested data, which is a way to organize data in the JSON format. The data mapper interprets the `.` character as nesting, which means if there are `.` characters in a property name that are not meant to be nesting, namely the ones in our current example: `product.add.event`, we need to escape this behavior by adding backslashes `\` before the `.` (`1`).

Now, we need to map this JSON property from the Edge Bridge event to its matching property in the XDM schema. Click the schema icon (`2`) to open the XDM property viewer window.

<img src="../assets/edge-bridge-tutorial/datastreams-mapping-xdm.png" alt="Select data from Edge Bridge event" width="1100"/>  

In the XDM property viewer window, click the dropdown arrows next to `commerce` (`1`) and `productListAdds` (`2`). Then select the `value` property (`3`) and click `Select` (`4`).

<img src="../assets/edge-bridge-tutorial/datastreams-mapping-xdm-property.png" alt="Select data from Edge Bridge event" width="1100"/>  

Repeat this process, adding new mappings for all of the other properties on the JSON data side (except for the `timestamp` property which is handled automatically by Edge), finalizing the mappings like this:

| JSON Property                           | XDM Property                       | trackAction        | trackState         |
| --------------------------------------- | ---------------------------------- | ------------------ | ------------------ |
| data.contextdata.product\\.add\\.event  | commerce.productListAdds.value     | :white_check_mark: |                    |
| data.contextdata.product\\.view\\.event | commerce.productListViews.value    |                    | :white_check_mark: |
| data.contextdata.product\\.id           | productListItems.SKU               | :white_check_mark: | :white_check_mark: |
| data.contextdata.product\\.name         | productListItems.name              | :white_check_mark: | :white_check_mark: |
| data.contextdata.product\\.units        | productListItems.quantity          | :white_check_mark: |                    |



Follow the instructions in the guide on mapping data [using Data Prep for Data Collection](./map-track-data-using-data-prep.md)

## Validation with Assurance
Check mapping feedback in Event transactions view

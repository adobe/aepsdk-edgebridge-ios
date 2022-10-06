# Migrating from Analytics mobile extension to the Edge Network using the Edge Bridge extension <!-- omit in toc -->

## Table of Contents <!-- omit in toc -->
- [Overview](#overview)
  - [Environment](#environment)
  - [Prerequisites](#prerequisites)
  - [Adobe Experience Platform setup](#adobe-experience-platform-setup)
  - [1. Set up mobile property](#1-set-up-mobile-property)
  - [2. Configure a Rule to forward PII events to Edge Network](#2-configure-a-rule-to-forward-pii-events-to-edge-network)
- [Client-side implementation](#client-side-implementation)
  - [1. Get a copy of the files (code and tutorial app)](#1-get-a-copy-of-the-files-code-and-tutorial-app)
  - [1. Install Edge Bridge using dependency manager (Swift Package Manager)](#1-install-edge-bridge-using-dependency-manager-swift-package-manager)
  - [2. Update Tutorial App Code to remove Analytics](#2-update-tutorial-app-code-to-remove-analytics)
  - [3. Update Tutorial App Code to Enable EdgeBridge functionality](#3-update-tutorial-app-code-to-enable-edgebridge-functionality)
  - [4. Run app](#4-run-app)
  - [5. `trackAction`/`trackState` implementation examples](#5-trackactiontrackstate-implementation-examples)
- [Initial validation with Assurance](#initial-validation-with-assurance)
  - [1. Set up the Assurance session](#1-set-up-the-assurance-session)
  - [2. Connect the app to the Assurance session](#2-connect-the-app-to-the-assurance-session)
  - [3. Event transactions view - check for EdgeBridge events](#3-event-transactions-view---check-for-edgebridge-events)
    - [`trackAction`/`trackState` events](#trackactiontrackstate-events)
    - [Rules-based events](#rules-based-events)
- [Data prep mapping](#data-prep-mapping)
- [Final validation using Assurance](#final-validation-using-assurance)

## Overview
This hands-on tutorial provides end-to-end instructions on how to migrate from sending data to Analytics to sending data to the Edge Network using the Edge Bridge mobile extension.

```mermaid
graph LR;
    step1(1<br/>Existing Adobe Analytics app) -->
    step2(2<br/>Adobe Experience Platform<br/>Update server-side configuration) --> 
    step3(3<br/>Edge Bridge<br/>Send event data to the Edge Network & Analytics) --> 
    step4(4<br/>Assurance<br/>Verify event data formats) -->
    step5(5<br/>Data mapper<br/>Map data to XDM - Edge network data format) -->
    step6(6<br/>Assurance<br/>Verify trackAction/trackState to XDM conversion)
```

### Environment
- macOS machine with a recent version of Xcode installed.
- Cocoapods installed.

### Prerequisites
- A timestamp enabled report suite is configured for mobile data collection.
- A tag (also known as mobile property) is configured in Data Collection UI which has Adobe Analytics extension installed and configured.

### Adobe Experience Platform setup
Before any app changes we need to set up some configuration items on the Adobe Experience Platform (AEP) side. The end goal of this section is to create a mobile property that controls the configuration settings for the various AEP extensions used in this tutorial.

### 1. Set up mobile property  
If you don't have an existing mobile property, see the [instructions on how to set up a new property](https://github.com/adobe/aepsdk-edge-ios/blob/tutorial-send-event/Documentation/Tutorials/edge-send-event-tutorial.md#1-create-a-schema).

The following AEP extension configurations should be installed:  

<details>
  <summary> Adobe Analytics </summary><p>

Open the **Catalog** and install the `Adobe Analytics` extension configuration.

<img src="../assets/edge-bridge-tutorial/mobile-property-catalog-analytics.png" alt="Catalog search for Adobe Experience Platform Edge Network" width="1100"/>  

In the extension configuration settings window, set the report suite ID (**1**) for each environment to the one for this tutorial. Then click `Save` (**2**)

<img src="../assets/edge-bridge-tutorial/mobile-property-analytics-settings.png" alt="Edge extension settings" width="1100"/>  

</p></details>

<details>
  <summary> AEP Assurance </summary><p>

Open the **Catalog** and install the `AEP Assurance` extension configuration.

<img src="../assets/edge-bridge-tutorial/mobile-property-catalog-assurance.png" alt="Catalog search for Adobe Experience Platform Edge Network" width="1100"/>  

</p></details>

<details>
  <summary> Adobe Experience Platform Edge Network </summary><p>

Go back to the `Catalog` and install the `Adobe Experience Platform Edge Network` extension configuration.

<img src="../assets/edge-bridge-tutorial/mobile-property-catalog-edge.png" alt="Catalog search for Adobe Experience Platform Edge Network" width="1100"/>  

In the extension configuration settings window, set the datastream for each environment (**1**) to the one created for this tutorial. Then click `Save` (**2**)

<img src="../assets/edge-bridge-tutorial/mobile-property-edge-settings.png" alt="Edge extension settings" width="1100"/>  

</p></details>

<details>
  <summary> Identity </summary><p>

Open the `Catalog` and install the `Identity` extension configuration. There are no settings for this extension.

<img src="../assets/edge-bridge-tutorial/mobile-property-catalog-identity.png" alt="Catalog search for Identity" width="1100"/>  

</p></details>

<details>
  <summary> Consent </summary><p>

Open the `Catalog` and install the `Consent` extension configuration.

<img src="../assets/edge-bridge-tutorial/mobile-property-catalog-consent.png" alt="Catalog search for Consent" width="1100"/>  

In the extension configuration settings window, the `Default Consent Level` should be set to `Yes` by default (**1**); for the tutorial app this setting is fine as-is, however when using this configuration in production apps, it should reflect the requirements of the company's actual data collection policy for the app. 

<img src="../assets/edge-bridge-tutorial/mobile-property-consent-settings.png" alt="Consent extension settings" width="1100"/>  

</p></details>

The following cards should be visible after all the extensions are installed: 

<img src="../assets/edge-bridge-tutorial/mobile-property-all-extensions.png" alt="All installed extensions" width="1100"/>  

### 2. Configure a Rule to forward PII events to Edge Network 
The collectPII API for Analytics does not send events to the Edge Network by default, and needs a rule to be configured in order to forward these events.

#### Create a rule <!-- omit in toc -->
1. On the Rules tab, select **Create New Rule**.
   - If your property already has rules, the button will be in the top right of the screen.
2. Give your rule an easily recognizable name (**1**) in your list of rules. In this example, the rule is named "Forward PII events to Edge Network".
3. Under the **EVENTS** section, select **Add** (**2**).



#### Define the event <!-- omit in toc -->

2. From the **Extension** dropdown list (**1**), select **Mobile Core**.
3. From the **Event Type** dropdown list (**2**), select **Collect PII**.
4. Select **Keep Changes** (**3**).

#### Define the action <!-- omit in toc -->
1. Under the Actions section, select **+ Add** (**1**).

2. From the **Extension** dropdown list (**1**), select **Adobe Analytics**.
3. From the **Action Type** dropdown list (**2**), select **Track**.
4. On the right side window, name the **Action** field "collect_pii".
5. Select **Keep Changes** (**3**).

#### Save the rule and rebuild your property <!-- omit in toc -->
1. After you complete your configuration, verify that your rule looks like the following:
2. Select **Save** (**1**).


## Client-side implementation
### 1. Get a copy of the files (code and tutorial app)
1. Open the code repository: https://github.com/adobe/aepsdk-edgebridge-ios
2. Click **Code** in the top right 
3. In the window that opens, click **Download ZIP**; by default it should land in your **Downloads** folder.
   - Optionally, move the ZIP to your **Documents** folder
4. Unzip the archived file by double clicking it, and keep this Finder window open, as we will need it later.

Now we can use the tutorial app to go through the changes required to install the Edge Bridge extension.

1. Open the Terminal app
   - Applications -> Utilities -> Terminal
   - Open Spotlight search (CMD + Space) and search for "terminal"
2. Type the following characters, but do not press return yet: `c` + `d` + `SPACE`  
You should see the following in your terminal: "cd " (the space after `cd` is important!).
```bash
cd 
```
7. Return to your Finder window that has the unzipped repository folder. Click and drag the folder into your Terminal window that has the `cd ` command typed. You should see something like: `cd /Users/tim/Documents/aepsdk-edgebridge-ios`  
8. Then press `return` to execute the command.

<details>
  <summary> What is <code>cd</code>? What did I just do? </summary><p>

`cd` is the terminal command for change directory; the command above changes your terminal's active directory to the repository we just copied.

The long string after is the full path (kind of like an address) to the code repository folder: `/Users/tim/Documents/aepsdk-edgebridge-ios`, taking our terminal window to the newly created repository!

</p></details>

Now that we're in the project directory, there's some setup we have to do; the app depends on packages which are not installed with the repository. To install them, run the command:

```bash
pod update
```

<details>
  <summary> Using Swift package manager instead? </summary><p>

**Swift Package Manager**
This tutorial assumes a project using Cocoapods for package dependency management, but if following along with a project that uses Swift package manager, refer to the [README for instructions on how to add the Edge Bridge package](../../README.md#swift-package-managerhttpsgithubcomappleswift-package-manager).

</p></details>

You should see the dependency manager CocoaPods installing the various packages required by the project. 

<details>
  <summary> Expected output </summary><p>

```
tim@Tims-MacBook-Pro aepsdk-edgebridge-ios % pod update
Update all pods
Updating local specs repositories
Analyzing dependencies
Downloading dependencies
Installing AEPAssurance (3.0.1)
Installing AEPCore (3.7.1)
Installing AEPEdge (1.4.1)
Installing AEPEdgeIdentity (1.1.0)
Installing AEPLifecycle (3.7.1)
Installing AEPRulesEngine (1.2.0)
Installing AEPServices (3.7.1)
Installing SwiftLint (0.44.0)
Generating Pods project
Integrating client project
Pod installation complete! There are 6 dependencies from the Podfile and 8 total pods installed.
tim@Tims-MacBook-Pro aepsdk-edgebridge-ios % 
```

</p></details>

### 1. Install Edge Bridge using dependency manager (Swift Package Manager)
Our next task is actually modifying the file that controls the package dependencies, adding the new extensions that will enable the Edge Bridge extension to function.

Open the project using the command:
```bash
open AEPEdgeBridge.xcworkspace
```

This should automatically open the Xcode IDE. In Xcode:
1. Click the dropdown chevron next to `Pods` in the left-side navigation panel.
2. Click the `Podfile` file.
3. Replace the section: 

```ruby
target 'EdgeBridgeTutorialApp' do
  pod 'AEPAnalytics'
  pod 'AEPCore'
  pod 'AEPServices'
end
```
With:

```ruby
target 'EdgeBridgeTutorialApp' do
  pod 'AEPAnalytics'
  pod 'AEPAssurance'
  pod 'AEPCore'
  pod 'AEPEdge'
  pod 'AEPEdgeConsent'
  pod 'AEPEdgeIdentity'
  pod 'AEPLifecycle'
  pod 'AEPServices'
end
```

4. Go back to your terminal window and run:
```bash
pod update
```
Cocoapods will use this updated configuration file to install the new packages (including the EdgeBridge extension itself!), which will allow us to add new functionality in the app's code. 

### 2. Update Tutorial App Code to remove Analytics
With the Edge Bridge extension handling `trackAction`/`trackState` API calls, we can remove the Analytics extension from the code and as a dependency.

There is one file we need to update to remove the Analytics extension. 
1. Click the dropdown chevron next to `EdgeBridgeTutorialApp` in the left-side navigation panel.
2. Click the dropdown chevron next to the `EdgeBridgeTutorialApp` folder.
3. Click the `AppDelegate.swift` file.

Inside you will see code blocks for this tutorial marked by a header and footer `EdgeBridge Tutorial - remove section (n/m)` (where `n` is the current section and `m` is the total number of sections in the file).

Simply delete everything between the header and footer, and make sure to cover all sections within the file.

### 3. Update Tutorial App Code to Enable EdgeBridge functionality
There are two files that need to be updated to enable the Edge Bridge extension:  
1. `AppDelegate.swift`
2. `SceneDelegate.swift`
   
Inside you will see code blocks for this tutorial that are greyed out, because they are commented out. They are marked by the header and footer `EdgeBridge Tutorial - code section n/m` (where `n` is the current section and `m` is the total number of sections in the file).

To uncomment the section and activate the code, simply add a forward slash at the front of the header:
```swift
/* EdgeBridge Tutorial - code section (1/2)
```
To:
```swift
//* EdgeBridge Tutorial - code section (1/2)
```
Make sure to uncomment all sections within the file (the total will tell you how many sections there are).

For details on the various Edge extensions used, see the [table of related projects](../../README.md#related-projects).

### 4. Run app   
In Xcode, select the app target you want to run, and the destination device to run it on (either simulator or physical device). Then press the play button.

You should see your application running on the device you selected, with logs being displayed in the console in Xcode. 

> **Note**
> If the debug console area is not shown by default, activate it by selecting:  
> View -> Debug Area -> Show Debug Area

### 5. `trackAction`/`trackState` implementation examples   
With Edge Bridge extension successfully installed and registered, you can make the regular Analytics `trackAction` and `trackState` calls, which will be captured by Edge Bridge extension and sent to the Edge Network.

Check `ContentView.swift` for implementation examples of both APIs. You can see the data payloads that are to be sent with the calls.

## Initial validation with Assurance
Assurance is the AEP tool for inspecting all events that Adobe extensions send out, in real time. It will allow us to see the flow of events, including the EdgeBridge conversion of `trackAction`/`trackState`.

### 1. Set up the Assurance session 
To create a new Assurance session and connect to it, see the instructions on [setting up an Assurance session](https://github.com/adobe/aepsdk-edge-ios/blob/dev/Documentation/Tutorials/edge-send-event-tutorial.md#1-set-up-the-assurance-session), using the base URL value:
```
edgebridgetutorialapp://
```

### 2. Connect the app to the Assurance session  
To connect the tutorial app to the Assurance session, see the instructions on [connecting the app to the Assurance session](https://github.com/adobe/aepsdk-edge-ios/blob/dev/Documentation/Tutorials/edge-send-event-tutorial.md#2-connect-to-the-app).

### 3. Event transactions view - check for EdgeBridge events  
#### `trackAction`/`trackState` events
In order to see EdgeBridge events, in the connected app instance:
1. Trigger a `trackAction` and/or `trackState` within the app which the Edge Bridge extension will convert into Edge events. This event will be captured by the Assurance extension and shown in the web session viewer.

<img src="../assets/edge-bridge-tutorial/simulator-track-buttons.jpg" alt="Simulator tracking buttons" width="400"/>

2. Click the `AnalyticsTrack` event (**1**) in the events table to see the event details in the right side window
3. Click the `RAW EVENT` dropdown (**2**) in the event details window to see the event data payload. 
4. Verify that the `contextdata` matches what was sent by the Analytics `trackAction`/`trackState` API.

<img src="../assets/edge-bridge-tutorial/assurance-analytics-track-event.jpg" alt="Simulator tracking buttons" width="800"/>

5. Now click the `Edge Bridge Request` event (**1**) in the events table
6. Click the `RAW EVENT` dropdown (**2**) in the event details window; notice the slight differences in the payload structure as a result of the `Edge Bridge Request` event conforming to the format of an Edge event.

<img src="../assets/edge-bridge-tutorial/assurance-edge-bridge-track-event.jpg" alt="Simulator tracking buttons" width="800"/>

Notice the differences in event data structure and format between the two types of events: Analytics (left) vs Edge (right) via Edge Bridge extension
The top level EventType is converted from a `generic.track` to `edge` (that is, Analytics generic track event -> Edge event) (**1**). The Edge Bridge extension also populates the standard XDM field for event type (`eventType`) in the event data payload. Also notice that the `contextdata` has moved from directly under `EventData` to under the generic Edge XDM `data` property (**2**).

<img src="../assets/edge-bridge-tutorial/analytics-edge-bridge-conversion.jpg" alt="Comparison of event data between analytics and edge bridge events" width="1100"/>

> **Note**
> The two new top level properties `xdm` and `data` are standard Edge event properties that are part of the Edge platform's XDM schema-based system for event data organization that enables powerful, customizable data processing. However, because the `contextdata` is not yet mapped to an XDM schema, it is not in a usable form for the Edge platform. We will solve this issue by mapping the event data to an XDM schema in the next section.

#### Rules-based events
Rules-based trackAction/trackState events are also converted to Edge events by the Edge Bridge extension. Select the **Trigger Consequence** button to trigger a rule that creates a trackAction event.

Just like the `trackAction`/`trackState` events above, the Edge Bridge extension will convert the PII trackAction event into an Edge event.

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

1. Copy and paste the JSON data into the datastreams JSON input box (**1**). 
2. Verify the uploaded JSON matches what is displayed in the `Preview sample data` section (**2**) and click `Next` (**3**).

<details>
  <summary> Getting the JSON data from Assurance </summary><p>

1. Navigate back to your Assurance session for the Edge Bridge app and select the `Edge Bridge Request` event (**1**)
2. Open the `RAW EVENT` dropdown and click and drag to select the `ACPExtensionEventData` value as shown, then copy the selected value (right click the highlighted selection and choose `Copy`, or use the copy keyboard shortcut `CMD + C`)  

<img src="../assets/edge-bridge-tutorial/assurance-edgebridge-mapping-data.png" alt="Select data from Edge Bridge event" width="1100"/>  

> **Note**
> To merge events, you would look for properties under `data` and `contextdata` that are unique between events and include them in the final data payload.

</p></details>

<img src="../assets/edge-bridge-tutorial/datastreams-json-paste.png" alt="Select data from Edge Bridge event" width="1100"/>  

3. Click the `Add new mapping` button (**1**).

<img src="../assets/edge-bridge-tutorial/datastreams-start-mapping.png" alt="Select data from Edge Bridge event" width="1100"/>  

4. A new entry for mapping will appear in the window; click the arrow button (**1**) next to the field `Select source field`.

<img src="../assets/edge-bridge-tutorial/datastreams-mapping-1.png" alt="Select data from Edge Bridge event" width="1100"/>  

5. In the JSON property viewer window, click the dropdown arrows next to `data` (**1**) and `contextdata` (**2**). 
6. Then select the first property to map, `product.add.event` (**3**) and click `Select` (**4**).

<img src="../assets/edge-bridge-tutorial/datastreams-select-property.png" alt="Select data from Edge Bridge event" width="1100"/>  

Notice that in the property viewer, you can see the data hierarchy, where `data` is at the top, `contextdata` is one level down, and `product.add.event` is one level below that. This is nested data, which is a way to organize data in the JSON format. 

> **Info**
> The data mapper interprets the `.` character as nesting, which means if there are `.` characters in a property name that are not meant to be nesting, namely the ones in our current example: `product.add.event`, we need to escape this behavior by adding backslashes `\` before the `.` (**1**).

7. Add backslashes `\` before the `.` characters as shown below (**1**).

Now, we need to map this JSON property from the Edge Bridge event to its matching property in the XDM schema. 

8. Click the schema icon (**2**) to open the XDM property viewer window.

<img src="../assets/edge-bridge-tutorial/datastreams-mapping-xdm.png" alt="Select data from Edge Bridge event" width="1100"/>  

9. In the XDM property viewer window, click the dropdown arrows next to `commerce` (**1**) and `productListAdds` (**2**). 
10. Then select the `value` property (**3**) and click `Select` (**4**).

<img src="../assets/edge-bridge-tutorial/datastreams-mapping-xdm-property.png" alt="Select data from Edge Bridge event" width="1100"/>  

11. Repeat this process, adding new mappings for all of the other properties on the JSON data side (except for the `timestamp` property which is handled automatically by Edge), finalizing the mappings like this:

| JSON Property                           | XDM Property                       | trackAction        | trackState         |
| --------------------------------------- | ---------------------------------- | ------------------ | ------------------ |
| data.contextdata.product\\.add\\.event  | commerce.productListAdds.value     | :white_check_mark: |                    |
| data.contextdata.product\\.view\\.event | commerce.productListViews.value    |                    | :white_check_mark: |
| data.contextdata.product\\.id           | productListItems.SKU               | :white_check_mark: | :white_check_mark: |
| data.contextdata.product\\.name         | productListItems.name              | :white_check_mark: | :white_check_mark: |
| data.contextdata.product\\.units        | productListItems.quantity          | :white_check_mark: |                    |

12. After completing all the mappings, click **Save**.

## Final validation using Assurance
Now that the mapping is set up in the datastream, we have the full pathway of data:
```mermaid
graph LR;
    step1(App<br/>Analytics trackAction/trackState) --> step2(App<br/>Edge Bridge conversion to Edge event) --> step3(Edge Network<br/>Datastream translation of payload from contextdata to Edge XDM) --> step4(Edge Network<br/>Routing XDM data using datastream to Analytics);
```

Check mapping feedback in Event transactions view

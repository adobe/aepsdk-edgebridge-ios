# Edge Bridge Data Format

The Adobe Experience Platform Edge Bridge extension maps the data sent in `trackAction` and `trackState` API calls to a specific format known to Adobe Analytics which requires no additional server-side mapping. This document outlines the data format applied to the tracking data.

As of version 5.0.0 of Adobe Experience Platform Edge Bridge for iOS, the table below shows how the `trackAction` and `trackState` parameters map to the `data` node of the Experience Event sent to Experience Platform Edge Network. Edge Network automatically maps these data variables to Analytics without additional server-side configuration. If you are using Edge Bridge version 4.x and mapping data to XDM in your datastream, adjustments are required for version 5.0.0.

| Data | Key path in the network request | Description |
| --- | --- | ---
| Action | `data.__adobe.analytics.linkName` | The custom link name in the Analytics hit. The field `data.__adobe.analytics.linkType` with value `lnk_o` is also automatically included. |
| State | `data.__adobe.analytics.pageName` | The page name in the Analytics hit.|
| Context data | `data.__adobe.analytics.contextData` | Context data is a map which includes the custom keys and values specified in the `trackAction` and `trackState` API calls. |
| Context data prefixed with "&&" | `data.__adobe.analytics` | Context data keys prefixed with "&&" are automatically mapped to Analytics variables and no longer include the "&&" prefix. For example, the key `&&products` is sent as `data.__adobe.analytics.products`. Please note that these keys must be known to Analytics and are case sensitive. Find the full list of supported Analytics variables [here](https://experienceleague.adobe.com/en/docs/analytics/implementation/aep-edge/data-var-mapping).|
| App identifier | `data.__adobe.analytics.contextData.a.AppID` | The application identifier is automatically added to every tracking event under the key name `a.AppID`.|
| Customer perspective | `data.__adobe.analytics.cp` | The customer perspective is automatically added to every tracking event. The values are either `foreground` or `background`. |

### Examples

Given the track action call: 

```swift
MobileCore.track(action: "action name", data: ["key": "value", "&&products": ";Running Shoes;1;69.95;event1|event2=55.99;eVar1=12345"])
```

The resulting Experience Event has the following payload:

```json
{
  "data":{
    "__adobe": {
      "analytics": {
        "linkName": "action name",
        "linkType": "lnk_o",
        "cp": "foreground",
        "products": ";Running Shoes;1;69.95;event1|event2=55.99;eVar1=12345",
        "contextData":{
          "a.AppID": "myApp 1.0 (1)",
          "key": "value"
        }
      }
    }
  }
}
```

Given the track state call:

```swift
MobileCore.track(state: "view name", data: ["&&events": "event5,event2=2"])
```
 
 The resulting Experience Event has the following payload:

```json
{
  "data":{
    "__adobe": {
      "analytics": {
        "pageName": "view name",
        "cp": "foreground",
        "events": "event5,event2=2",
        "contextData":{
          "a.AppID": "myApp 1.0 (1)"
        }
      }
    }
  }
}
```
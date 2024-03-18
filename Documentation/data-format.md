# Edge Bridge Data Format

The AEP Edge Bridge extension maps the data sent in `trackAction` and `trackState` API calls to a specific format known to Analytics which requires no additional server-side mapping. This document outlines the data format applied to the tracking data.


As of version 5.0.0 of AEP Edge Bridge for iOS, the following table lists the mapping of the `trackAction` and `trackState` parameters to the "data" node of the Experience Event sent to the Edge Network. Adobe Experience Platform Edge Network automatically maps these data variables into Adobe Analytics without additional server-side configuration.


| Data | Key path in the network request | Description |
| --- | --- | ---
| action | `data.__adobe.analytics.linkName` | Additionally, the field `data.__adobe.analytics.linkType` with value `lnk_o` is automatically included. |
| state | `data.__adobe.analytics.pageName` | |
| context data | `data.__adobe.analytics.contextData` | Context data is a map which includes the custom keys and values specified in the `trackAction` and `trackState` API calls. |
| && prefixed context data | `data.__adobe.analytics` | Context data keys prefixed with `&&` must be known to Analytics and are case sensitive. When mapped to the event, the key's name does not include the "&&" prefix. For example, "&&products" is sent as `data.__adobe.analytics.products`.|
| app identifier | `data.__adobe.analytics.contextData.a.AppID` | The application identifier is automatically added to every tracking event. Note the key name is "a.AppID".|
| customer perspective | `data.__adobe.analytics.cp` | The customer perspective is automatically added to every tracking event. The values are either "foreground" or "background". |

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
                "a.AppID": "myApp 1.0 (1)",
            }
        }
    }
 }
```
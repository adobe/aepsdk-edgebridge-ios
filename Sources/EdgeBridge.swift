//
// Copyright 2022 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import AEPCore
import AEPServices
import Foundation

@objc(AEPMobileEdgeBridge)
@available(iOSApplicationExtension, unavailable)
@available(tvOSApplicationExtension, unavailable)
public class EdgeBridge: NSObject, Extension {

    public let name = EdgeBridgeConstants.EXTENSION_NAME
    public let friendlyName = EdgeBridgeConstants.FRIENDLY_NAME
    public static let extensionVersion = EdgeBridgeConstants.EXTENSION_VERSION
    public let metadata: [String: String]? = nil
    public let runtime: ExtensionRuntime

    // Helper with internal access for testing
    var bridgeHelper: EdgeBridgeHelper = EdgeBridgeHelperImpl()

    private lazy var applicationIdentifier: String = {
        getApplicationIdentifier()
    }()

    public required init?(runtime: ExtensionRuntime) {
        self.runtime = runtime
        super.init()
    }

    public func onRegistered() {
        registerListener(type: EventType.genericTrack,
                         source: EventSource.requestContent,
                         listener: handleTrackRequest)

        registerListener(type: EventType.rulesEngine,
                         source: EventSource.responseContent,
                         listener: handleRuleEngineResponse)
    }

    public func onUnregistered() {}

    /// Called before each `Event` processed by this extension
    /// - Parameter event: event that will be processed next
    /// - Returns: always returns true
    public func readyForEvent(_ event: Event) -> Bool {
        return true
    }

    /// Handles generic Analytics track events coming from the public APIs.
    /// - Parameter event: the generic track request event
    private func handleTrackRequest(_ event: Event) {
        guard let eventData = event.data, !eventData.isEmpty else {
            Log.debug(label: EdgeBridgeConstants.LOG_TAG, "Unable to handle track request event with id '\(event.id.uuidString)': event data is missing or empty.")
            return
        }

        dispatchTrackRequest(data: eventData, parentEvent: event)
    }

    ///  Handles Analytics track events generated by a rule consequence.
    ///  - Parameter event: the rules engine response event
    private func handleRuleEngineResponse(_ event: Event) {
        if event.data == nil {
            Log.trace(label: EdgeBridgeConstants.LOG_TAG, "Ignoring Rule Engine response event with id '\(event.id.uuidString)': event data is missing.")
            return
        }
        guard let consequence = event.data?["triggeredconsequence"] as? [String: Any] else {
            Log.trace(label: EdgeBridgeConstants.LOG_TAG, "Ignoring Rule Engine response event with id '\(event.id.uuidString)': consequence data is missing.")
            return
        }

        guard let consequenceType = consequence["type"] as? String, consequenceType == "an" else {
            return
        }
        if consequence["id"] as? String == nil {
            Log.trace(label: EdgeBridgeConstants.LOG_TAG, "Ignoring Rule Engine response event with id '\(event.id.uuidString)': consequence id is missing.")
            return
        }

        guard let consequenceDetail = consequence["detail"] as? [String: Any], !consequenceDetail.isEmpty else {
            Log.trace(label: EdgeBridgeConstants.LOG_TAG, "Ignoring Rule Engine response event with id '\(event.id.uuidString)': consequence detail is missing or empty.")
            return
        }

        dispatchTrackRequest(data: consequenceDetail, parentEvent: event)
    }

    /// Helper to create and dispatch an experience event.
    /// - Parameters:
    ///   - data: dictionary containing free-form data to send to Edge Network
    ///   - parentEvent: the triggering parent event used for event chaining; its timestamp is set as xdm.timestamp
    private func dispatchTrackRequest(data: [String: Any], parentEvent: Event) {
        let mappedData = formatData(data)

        if mappedData.isEmpty {
            Log.warning(label: EdgeBridgeConstants.LOG_TAG, "Event '\(parentEvent.id.uuidString)' did not contain any mappable data. Experience event not dispatched.")
            return
        }

        let xdmEventData: [String: Any] = [
            "data": mappedData,
            "xdm": [
                "timestamp": parentEvent.timestamp.getISO8601UTCDateWithMilliseconds(),
                "eventType": EdgeBridgeConstants.JsonValues.EVENT_TYPE
            ]
        ]

        let event = parentEvent.createChainedEvent(name: EdgeBridgeConstants.EventNames.EDGE_BRIDGE_REQUEST,
                                                   type: EventType.edge,
                                                   source: EventSource.requestContent,
                                                   data: xdmEventData)

        runtime.dispatch(event: event)
    }

    /// Formats track event data to the required Analytics Edge translator format under the `data.__adobe.analytics` object.
    ///
    /// The following is the mapping logic:
    /// - The "action" field is mapped to "data.__adobe.analytics.linkName", plus "data.__adobe.analytics.linkType" is set to "other".
    /// - The "state" field is mapped to "data.__adobe.analytics.pageName".
    /// - Any "contextData" keys which use the "&&" prefix are mapped to "data.__adobe.analytics" with the prefix removed.
    /// - Any "contextData" keys which do not use the "&&" prefix are mapped to "data.__adobe.analytics.contextdata".
    /// - Any additional fields are passed through and left directly under the "data" object.
    ///
    /// As an example, the following track event data:
    /// ```json
    ///  {
    ///     "action": "action name",
    ///     "contextdata": {
    ///        "&&c1": "propValue1",
    ///        "key1": "value1"
    ///     }
    ///     "key2": "value2"
    ///  }
    ///  ```
    ///  Is mapped to:
    ///  ```json
    ///  {
    ///    "data": {
    ///      "__adobe": {
    ///        "analytics": {
    ///          "linkName": "action name",
    ///          "linkType": "other",
    ///          "c1": "propValue1"
    ///          "contextData": {
    ///            "key1": "value1"
    ///          }
    ///        }
    ///      }
    ///      "key2": "value2"
    ///    }
    ///  }
    ///  ```
    ///
    ///  Note, empty keys are not allowed and ignored.
    ///
    /// - Parameter data: track event data
    /// - Returns: data formatted for the Analytics Edge translator.
    private func formatData(_ data: [String: Any]) -> [String: Any] {
        var mutableData = data // mutable copy of data
        var analyticsData: [String: Any] = [:] // __adobe.analytics data

        if let contextData = mutableData.removeValue(forKey: EdgeBridgeConstants.MobileCoreKeys.CONTEXT_DATA) as? [String: Any?], !contextData.isEmpty {
            var prefixedData: [String: Any] = [:]
            var nonprefixedData: [String: Any] = [:]

            let cleanedContextData: [String: Any] = cleanContextData(contextData)
            for (key, value) in cleanedContextData {
                if key.isEmpty {
                    Log.debug(label: EdgeBridgeConstants.LOG_TAG, "Dropping key '\(key)' with value '\(value)'. Key must be non-empty String.")
                    continue
                }

                if key.hasPrefix(EdgeBridgeConstants.AnalyticsValues.PREFIX) {
                    let newKey = String(key.dropFirst(EdgeBridgeConstants.AnalyticsValues.PREFIX.count))
                    if !newKey.isEmpty {
                        prefixedData[newKey] = value
                    } else {
                        Log.debug(label: EdgeBridgeConstants.LOG_TAG,
                                  "Dropping key '\(key)' with value '\(value)'. Key minus prefix '\(EdgeBridgeConstants.AnalyticsValues.PREFIX)' must be non-empty String.")
                    }
                } else {
                    nonprefixedData[key] = value
                }
            }

            if !prefixedData.isEmpty {
                analyticsData = prefixedData
            }

            if !nonprefixedData.isEmpty {
                analyticsData[EdgeBridgeConstants.AnalyticsKeys.CONTEXT_DATA] = nonprefixedData
            }
        }

        if let action = mutableData.removeValue(forKey: EdgeBridgeConstants.MobileCoreKeys.ACTION) as? String, !action.isEmpty {
            analyticsData[EdgeBridgeConstants.AnalyticsKeys.LINK_NAME] = action
            analyticsData[EdgeBridgeConstants.AnalyticsKeys.LINK_TYPE] = EdgeBridgeConstants.AnalyticsValues.OTHER
        }

        if let state = mutableData.removeValue(forKey: EdgeBridgeConstants.MobileCoreKeys.STATE) as? String, !state.isEmpty {
            analyticsData[EdgeBridgeConstants.AnalyticsKeys.PAGE_NAME] = state
        }

        if !analyticsData.isEmpty {
            if var contextData = analyticsData[EdgeBridgeConstants.AnalyticsKeys.CONTEXT_DATA] as? [String: Any] {
                contextData[EdgeBridgeConstants.AnalyticsKeys.APPLICATION_ID] = applicationIdentifier
                analyticsData[EdgeBridgeConstants.AnalyticsKeys.CONTEXT_DATA] = contextData
            } else {
                analyticsData[EdgeBridgeConstants.AnalyticsKeys.CONTEXT_DATA] = [EdgeBridgeConstants.AnalyticsKeys.APPLICATION_ID: applicationIdentifier]
            }

            analyticsData[EdgeBridgeConstants.AnalyticsKeys.CUSTOMER_PERSPECTIVE] = getApplicationState()

            mutableData[EdgeBridgeConstants.AnalyticsKeys.ADOBE] = [EdgeBridgeConstants.AnalyticsKeys.ANALYTICS: analyticsData]
        }

        return mutableData
    }

    /// Clean context data values.
    /// Context data values may only be of type Number, String, or Character. Other values are filered out.
    ///
    /// - Parameter data: context data to be cleaned
    /// - Returns: dictionary where values are only of type String, Number, or Character
    private func cleanContextData(_ data: [String: Any?]) -> [String: Any] {

        let cleanedData = data.filter {
            switch $0.value {
            case is NSNumber, is String, is Character:
                return true
            default:
                Log.debug(label: EdgeBridgeConstants.LOG_TAG,
                          "cleanContextData - Dropping key '\(String(describing: $0.key))' " +
                          "with value '\(String(describing: $0.value))'. " +
                          "Value must be String, Number, Bool or Character.")
                return false
            }
        }

        return cleanedData as [String: Any]
    }

    /// Combines the application name, version, and version code into a formatted application identifier
    /// Returns the application identifier formatted as "appName appVersion (appBuildNumber)".
    ///
    /// - Return: `String` formatted Application identifier
    private func getApplicationIdentifier() -> String {
        let systemInfoService = ServiceProvider.shared.systemInfoService
        let applicationName = systemInfoService.getApplicationName() ?? ""
        let applicationVersion = systemInfoService.getApplicationVersionNumber() ?? ""
        let applicationBuildNumber = systemInfoService.getApplicationBuildNumber() ?? ""
        // Make sure that the formatted identifier removes white space if any of the values are empty, and remove the () version wrapper if version is empty as well
        return "\(applicationName) \(applicationVersion) (\(applicationBuildNumber))"
            .replacingOccurrences(of: "  ", with: " ")
            .replacingOccurrences(of: "()", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Get the application state variable.
    ///
    /// - Returns: "background" if the application state is `.background`, "foreground" for all other cases
    private func getApplicationState() -> String {
        return bridgeHelper.getApplicationState() == .background ?
            EdgeBridgeConstants.AnalyticsValues.APP_STATE_BACKGROUND : EdgeBridgeConstants.AnalyticsValues.APP_STATE_FOREGROUND
    }
}

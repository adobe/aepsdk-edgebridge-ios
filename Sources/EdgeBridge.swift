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
public class EdgeBridge: NSObject, Extension {

    public let name = EdgeBridgeConstants.EXTENSION_NAME
    public let friendlyName = EdgeBridgeConstants.FRIENDLY_NAME
    public static let extensionVersion = EdgeBridgeConstants.EXTENSION_VERSION
    public let metadata: [String: String]? = nil
    public let runtime: ExtensionRuntime

    let contextDataCapturer = ContextDataCapturer()

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

        registerListener(type: EventType.edgeBridge,
                         source: EventSource.startCapture,
                         listener: handleCaptureRequest)

        registerListener(type: EventType.edgeBridge,
                         source: EventSource.stopCapture,
                         listener: handleCaptureRequest)
    }

    public func onUnregistered() {}

    /// Called before each `Event` processed by this extension
    /// - Parameter event: event that will be processed next
    /// - Returns: always returns true
    public func readyForEvent(_ event: Event) -> Bool {
        return true
    }

    private func handleCaptureContextData(event: Event) {
        // add to existing list
        contextDataCapturer.addEvent(event: event)
    }

    private func handleCaptureRequest(_ event: Event) {
        switch event.source {
        case EventSource.startCapture:
            contextDataCapturer.startCapture()
        case EventSource.stopCapture:
            // Context data capture output options with defaults
            // Merge defaults to true
            let withMerge: Bool = event.data?[EdgeBridgeConstants.EventDataKeys.ContextDataKeys.CONTEXT_DATA_OUTPUT_WITH_MERGE] as? Bool ?? true
            // Case sensitive key match defaults to true
            let isMergeCaseSensitive: Bool = event.data?[EdgeBridgeConstants.EventDataKeys.ContextDataKeys.CONTEXT_DATA_MERGE_IS_CASE_SENSITIVE] as? Bool ?? true
            contextDataCapturer.stopCapture(withMerge: withMerge, isMergeCaseSensitive: isMergeCaseSensitive)
        }
    }

    /// Handles generic Analytics track events coming from the public APIs.
    /// - Parameter event: the generic track request event
    private func handleTrackRequest(_ event: Event) {
        guard let eventData = event.data, !eventData.isEmpty else {
            Log.debug(label: EdgeBridgeConstants.LOG_TAG, "Unable to handle track request event with id '\(event.id.uuidString)': event data is missing or empty.")
            return
        }

        dispatchTrackRequest(data: eventData, timestamp: event.timestamp)
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

        dispatchTrackRequest(data: consequenceDetail, timestamp: event.timestamp)
    }

    /// Helper to create and dispatch an experience event.
    /// - Parameters:
    ///   - data: dictionary containing free-form data to send to Edge Network
    ///   - timestamp: timestamp of Event
    private func dispatchTrackRequest(data: [String: Any], timestamp: Date) {
        let xdmEventData: [String: Any] = [
            "data": data,
            "xdm": [
                "timestamp": timestamp.getISO8601UTCDateWithMilliseconds(),
                "eventType": EdgeBridgeConstants.JsonValues.EVENT_TYPE
            ]
        ]

        let xdmEvent = Event(name: EdgeBridgeConstants.EventNames.EDGE_BRIDGE_REQUEST,
                             type: EventType.edge,
                             source: EventSource.requestContent,
                             data: xdmEventData)

        runtime.dispatch(event: xdmEvent)
        contextDataCapturer.addEvent(event: xdmEvent)
    }
}

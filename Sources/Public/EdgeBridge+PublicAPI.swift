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

/// Defines the public interface for the EdgeBridge extension
public extension EdgeBridge {
    /// Starts context data capture session, hooking into Edge Bridge's dispatch of events.
    public static func startContextDataCaptureSession() {
        // Dispatch event to edgebridge to signal start capture of context data
        let event = Event(name: EdgeBridgeConstants.EventNames.EDGE_BRDIGE_START_CONTEXT_DATA_CAPTURE,
                          type: EventType.edgeBridge,
                          source: EventSource.startCapture,
                          data: nil)

        MobileCore.dispatch(event: event)
    }

    /// Stops context data capture session, outputting the merge result using the case sentivity setting applied, and removing captured events from memory.
    /// - Parameters:
    ///     - withMerge: Controls if merge logic is applied to captured `Event`s
    ///     - isMergeCaseSensitive: Controls if merge logic for matching keys uses case sensitive compare or not
    public static func stopContextDataCaptureSession(withMerge: Bool, isMergeCaseSensitive: Bool) {
        // Dispatch event to edgebridge to signal stop capture of context data
        let outputOptions: [String: Any] = [
            EdgeBridgeConstants.EventDataKeys.ContextDataKeys.CONTEXT_DATA_OUTPUT_WITH_MERGE: withMerge,
            EdgeBridgeConstants.EventDataKeys.ContextDataKeys.CONTEXT_DATA_MERGE_IS_CASE_SENSITIVE: isMergeCaseSensitive
        ]

        let event = Event(name: EdgeBridgeConstants.EventNames.EDGE_BRDIGE_START_CONTEXT_DATA_CAPTURE,
                          type: EventType.edgeBridge,
                          source: EventSource.stopCapture,
                          data: outputOptions)

        MobileCore.dispatch(event: event)
    }
}

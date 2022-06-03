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

import Foundation

enum FunctionalTestConst {

    enum EventType {
        static let INSTRUMENTED_EXTENSION = "com.adobe.eventType.instrumentedExtension"
    }

    enum EventSource {
        static let SHARED_STATE_REQUEST = "com.adobe.eventSource.requestState"
        static let SHARED_STATE_RESPONSE = "com.adobe.eventSource.responseState"
        static let UNREGISTER_EXTENSION = "com.adobe.eventSource.unregisterExtension"
    }

    enum EventDataKey {
        static let STATE_OWNER = "stateowner"
        static let STATE = "state"
    }

    enum Defaults {
        static let WAIT_EVENT_TIMEOUT: TimeInterval = 2
        static let WAIT_SHARED_STATE_TIMEOUT: TimeInterval = 3
        static let WAIT_NETWORK_REQUEST_TIMEOUT: TimeInterval = 2
        static let WAIT_TIMEOUT: UInt32 = 1 // used when no expectation is set
    }
}

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

enum EdgeBridgeConstants {
    static let EXTENSION_NAME = "com.adobe.edge.bridge"
    static let FRIENDLY_NAME = "Edge Bridge"
    static let EXTENSION_VERSION = "4.1.0"
    static let LOG_TAG = FRIENDLY_NAME

    enum EventNames {
        static let EDGE_BRIDGE_REQUEST = "Edge Bridge Request"
    }

    enum JsonValues {
        static let EVENT_TYPE = "analytics.track"
    }
}

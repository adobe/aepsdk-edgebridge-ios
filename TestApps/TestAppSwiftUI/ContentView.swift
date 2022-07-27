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
import SwiftUI
import AEPEdgeBridge

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(alignment: .center, spacing: 20, content: {
                NavigationLink(
                    destination: AssuranceView(),
                    label: {
                        Text("Assurance")
                    })
                Divider()
                TrackView()
                Divider()
            })
        }
    }
}

struct TrackView: View {
    @State private var pushToken: Data?

    var body: some View {
        VStack {
            Button("Track Action", action: {
                // Dispatch an Analytics track action event which is handled by the
                // Edge Bridge extension which forwards it to the Edge Network.

                let data: [String: Any] = ["product.id": "12345", "product.add.event": "1", "product.name": "wide_brim_sunhat", "product.units": "1"]
                MobileCore.track(action: "add_to_cart", data: data)
            }).padding()

            Button("Track State", action: {
                // Dispatch an Analytics track state event which is handled by the
                // Edge Bridge extension which forwards it to the Edge Network.

                let data: [String: Any] = ["product.name": "wide_brim_sunhat", "product.id": "12345", "product.view.event": "1"]
                MobileCore.track(state: "hats/sunhat/wide_brim_sunhat_id12345", data: data)
            }).padding()

            Button("Trigger Consequence", action: {
                // Configure the Data Collection Mobile Property with a Rule to dispatch
                // an Analytics event when a PII event is dispatched in the SDK.
                // Without the rule, this button will not forward a track call to the Edge Network.
                MobileCore.collectPii(["key": "trigger"])
            }).padding()
            
            Button("Start Context Data Capture", action: {
                EdgeBridge.startContextDataCaptureSession(isKeyMatchCaseInsensitive: false)
                let optionalBool: Bool? = true
                let optionalString: String? = "hello"
                let optionalInt: Int? = 123
                let data: [String: Any] = [
                    "product.id": optionalInt,
                    "PRODUCT.add.event": optionalString,
                    "key1": "val1",
                    "key2": "val1",
                    "key3": "val1",
                    "pRODuct.name": [
                        "key1": "value1",
                        "key2": 2.1
                    ],
                    "product.units": "1"]
                MobileCore.track(action: "custom_test_action1", data: data)
                
                let data2: [String: Any] = [
                    "product.id": 12345,
                    "product.add.event": 1,
                    "product.name": [
                        "key1": "value1",
                        "key2": 2.1,
                        "keyunique": "something"
                    ],
                    "product.units": "1"]
                MobileCore.track(action: "custom_test_action2", data: data2)
            }).padding()
            
            Button("Output Context Data Capture", action: {
                let data: [String: Any] = [
                    "Product.id": 12345,
                    "PRODUCT.add.event": 1,
                    "pRODuct.name": [
                        "key1": "value1",
                        "key2": 2.1
                    ],
                    "product.units": "1"]
                MobileCore.track(action: "custom_test_action1", data: data)
                
                
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    EdgeBridge.outputCapturedContextData(withMerge: true)
                }
                
            }).padding()
            
            Button("Stop Context Data Capture", action: {
                EdgeBridge.stopContextDataCaptureSession()
            }).padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

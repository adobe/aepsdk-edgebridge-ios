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

struct ContentView: View {
    var body: some View {
        TrackView()
    }
}

struct TrackView: View {
    @State private var pushToken: Data?

    var body: some View {
        VStack {
            Button("Track Action", action: {
                // Dispatch an Analytics track action event which is handled by the
                // Edge Bridge extension which forwards it to the Edge Network.
                // This track action represents a purchase event of two products
                let data: [String: Any] = [
                    "&&products": ";Running Shoes;1;69.95;event1|event2=55.99;eVar1=12345,;Running Socks;10;29.99;event2=10.95;eVar1=54321",
                    "&&events": "event5,purchase",
                    "myapp.promotion": "a0138"
                ]
                MobileCore.track(action: "purchase", data: data)
            }).padding()

            Button("Track State", action: {
                // Dispatch an Analytics track state event which is handled by the
                // Edge Bridge extension which forwards it to the Edge Network.
                // This track state represents a product view
                let data: [String: Any] = [
                    "&&products": ";Running Shoes;1;69.95;prodView|event2=55.99;eVar1=12345",
                    "myapp.category": "189025",
                    "myapp.promotion": "a0138"
                ]
                MobileCore.track(state: "products/189025/runningshoes/12345", data: data)
            }).padding()

            Button("Trigger Rule", action: {
                // Configure the Data Collection Mobile Property with a Rule to dispatch
                // an Analytics event when a PII event is dispatched in the SDK.
                // Without the rule, this button will not forward a track call to the Edge Network.
                MobileCore.collectPii(["key": "trigger"])
            }).padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

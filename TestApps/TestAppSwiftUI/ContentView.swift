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
            Button("Track Action with products and events", action: {
                // Dispatch an Analytics track action event which is handled by the
                // Edge Bridge extension which forwards it to the Edge Network.
                // This track action represents a purchase event of two products
                let data: [String: Any] = [
                    "&&products": "Washing Machines;1234;1;1600;event1|event2|event3=200;eVar1=LG Washing Machine 2000|eVar2=LG 2000 standard|eVar3=abc123|eVar4=full coverage|eVar5=2 year,Dryers;4567;1;500;event1;eVar1=LG Dryer 2000,Kitchen Appliances;8910;1;1000;event1|event2|event3=300;eVar1=LG Dishwasher 4000|eVar2=LG 2000 extended|eVar4=labor coverage|eVar5=3 year",
                    "&&events": "event1,event2=3,event3=5.99,event10,event11,event100:123456,event101=5:123456,scOpen,scAdd"
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

            Button("Trigger Consequence", action: {
                // Configure the Data Collection Mobile Property with a Rule to dispatch
                // an Analytics event when a PII event is dispatched in the SDK.
                // Without the rule, this button will not forward a track call to the Edge Network.
                MobileCore.collectPii(["key": "trigger"])
            }).padding()

            Button("Track State contextData mapping", action: {
                // Dispatch an Analytics track state event which is handled by the
                // Edge Bridge extension which forwards it to the Edge Network.
                // This track state represents a product view
                let data: [String: Any] = [
                    "&&products": ";Running Socks;10;29.99;event2=10.95;eVar1=54321",
                    "&&events": "event6=2,prodView",
                    "&&c1": "prop1_shortName",
                    "&&prop2": "prop2_longName",
                    "&&v5": "evar5_shortName",
                    "&&evar10": "evar10_longName"
                ]
                MobileCore.track(state: "track state contextData mapping", data: data)
            }).padding()

            Button("Track State contextData mixed case", action: {
                // Dispatch an Analytics track state event which is handled by the
                // Edge Bridge extension which forwards it to the Edge Network.
                // This track state represents a product view
                let data: [String: Any] = [
                    "&&PRODUCTS": ";sunglasses;10;29.99;event2=10.95;eVar1=54321",
                    "&&EvEnTs": "event60=5,scCheckout",
                    "&&C1": "C1_shortName",
                    "&&PROP20": "PROP20_longName",
                    "&&V15": "V15_shortName",
                    "&&eVar11": "eVar11_longName",
                    "myAppName": "awesome app",
                    "myappname": "super duper"
                ]
                MobileCore.track(state: "track state contextData mixed case", data: data)
            }).padding()

            Button("Track State trigger attach data", action: {
                // Dispatch an Analytics track state event which is handled by the
                // Edge Bridge extension which forwards it to the Edge Network.
                // This track state represents a product view
                let data: [String: Any] = [
                    "attachData": true,
                    "&&c5": "attach data"
                ]
                MobileCore.track(state: "track state trigger attach data", data: data)
            }).padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

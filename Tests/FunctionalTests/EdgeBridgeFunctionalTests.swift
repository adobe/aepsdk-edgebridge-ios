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
import XCTest

import AEPCore
import AEPEdge
import AEPEdgeBridge
import AEPEdgeIdentity
import AEPServices

class EdgeBridgeFunctionalTests: FunctionalTestBase {
    private let edgeInteractEndpoint = "https://edge.adobedc.net/ee/v1/interact?"

    public class override func setUp() {
        super.setUp()
        FunctionalTestBase.debugEnabled = true
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        FileManager.default.clearCache()

        // hub shared state update for 1 extension versions Edge, Identity, Configuration, EventHub shared state updates
        setExpectationEvent(type: EventType.hub, source: EventSource.sharedState, expectedCount: 4)

        // expectations for update config request&response events
        setExpectationEvent(type: EventType.configuration, source: EventSource.requestContent, expectedCount: 1)
        setExpectationEvent(type: EventType.configuration, source: EventSource.responseContent, expectedCount: 1)

        // wait for async registration because the EventHub is already started in FunctionalTestBase
        let waitForRegistration = CountDownLatch(1)
        MobileCore.registerExtensions([Identity.self, Edge.self, EdgeBridge.self], {
            print("Extensions registration is complete")
            waitForRegistration.countDown()
        })
        XCTAssertEqual(DispatchTimeoutResult.success, waitForRegistration.await(timeout: 2))
        MobileCore.updateConfigurationWith(configDict: ["edge.configId": "12345-example"])

        assertExpectedEvents(ignoreUnexpectedEvents: false)
        resetTestExpectations()
    }

    func testTrackState_sendsEdgeExperienceEvent() {
        setExpectationNetworkRequest(url: edgeInteractEndpoint, httpMethod: .post, expectedCount: 1)

        MobileCore.track(state: "Test State", data: ["testKey": "testValue"])

        // verify
        assertNetworkRequestsCount()
        let networkRequests = getNetworkRequestsWith(url: edgeInteractEndpoint, httpMethod: .post)
        XCTAssertEqual(1, networkRequests.count)
        let requestData = getFlattenNetworkRequestBody(networkRequests[0])
        XCTAssertEqual("analytics.track", requestData["events[0].xdm.eventType"] as? String)
        XCTAssertNotNil(requestData["events[0].xdm.timestamp"] as? String)
        XCTAssertNotNil(requestData["events[0].xdm._id"] as? String)
        XCTAssertEqual("Test State", requestData["events[0].data.state"] as? String)
        XCTAssertEqual("testValue", requestData["events[0].data.contextdata.testKey"] as? String)
    }

    func testTrackAction_sendsCorrectRequestEvent() {
        setExpectationNetworkRequest(url: edgeInteractEndpoint, httpMethod: .post, expectedCount: 1)

        MobileCore.track(action: "Test Action", data: ["testKey": "testValue"])

        // verify
        assertNetworkRequestsCount()
        let networkRequests = getNetworkRequestsWith(url: edgeInteractEndpoint, httpMethod: .post)
        XCTAssertEqual(1, networkRequests.count)
        let requestData = getFlattenNetworkRequestBody(networkRequests[0])
        XCTAssertEqual("analytics.track", requestData["events[0].xdm.eventType"] as? String)
        XCTAssertNotNil(requestData["events[0].xdm.timestamp"] as? String)
        XCTAssertNotNil(requestData["events[0].xdm._id"] as? String)
        XCTAssertEqual("Test Action", requestData["events[0].data.action"] as? String)
        XCTAssertEqual("testValue", requestData["events[0].data.contextdata.testKey"] as? String)
    }

    func testRulesEngineResponse_sendsCorrectRequestEvent() {
        updateConfigurationWithRules(localRulesName: "rules_analytics")
        resetTestExpectations()

        setExpectationNetworkRequest(url: edgeInteractEndpoint, httpMethod: .post, expectedCount: 1)

        MobileCore.collectPii(["key": "value"]) // triggers Analytics rule

        // verify
        assertNetworkRequestsCount()
        let networkRequests = getNetworkRequestsWith(url: edgeInteractEndpoint, httpMethod: .post)
        XCTAssertEqual(1, networkRequests.count)
        let requestData = getFlattenNetworkRequestBody(networkRequests[0])
        XCTAssertEqual("analytics.track", requestData["events[0].xdm.eventType"] as? String)
        XCTAssertNotNil(requestData["events[0].xdm.timestamp"] as? String)
        XCTAssertNotNil(requestData["events[0].xdm._id"] as? String)
        // data is defined in the rule, not from the dispatched PII event
        XCTAssertEqual("Rule Action", requestData["events[0].data.action"] as? String)
        XCTAssertEqual("Rule State", requestData["events[0].data.state"] as? String)
        XCTAssertEqual("testValue", requestData["events[0].data.contextdata.testKey"] as? String)
    }

    /// Helper function to update configuration with rules URL and mock response with a local zip file.
    /// - Parameter localRulesName: name of bundled file with rules definition without '.zip' extension
    private func updateConfigurationWithRules(localRulesName: String) {
        let filePath = Bundle(for: type(of: self)).url(forResource: localRulesName, withExtension: ".zip")
        let data = try? Data(contentsOf: filePath!)

        let response = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: [:])
        let responseConnection = HttpConnection(data: data, response: response, error: nil)
        setNetworkResponseFor(url: "https://rules.com/\(localRulesName).zip", httpMethod: .get, responseHttpConnection: responseConnection)
        setExpectationNetworkRequest(url: "https://rules.com/\(localRulesName).zip", httpMethod: .get, expectedCount: 1)

        MobileCore.updateConfigurationWith(configDict: ["rules.url": "https://rules.com/\(localRulesName).zip"])

        assertNetworkRequestsCount()
    }

}

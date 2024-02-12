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
import AEPTestUtils

class EdgeBridgeFunctionalTests: TestBase, AnyCodableAsserts {
    private let edgeInteractEndpoint = "https://edge.adobedc.net/ee/v1/interact?"

    private let mockNetworkService: MockNetworkService = MockNetworkService()

    public class override func setUp() {
        super.setUp()
        TestBase.debugEnabled = true
    }

    override func setUp() {
        super.setUp()
        ServiceProvider.shared.networkService = mockNetworkService
        continueAfterFailure = false
        FileManager.default.clearCache()
        FileManager.default.removeAdobeCacheDirectory()

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
        mockNetworkService.reset()
    }

    // Runs after each test case
    override func tearDown() {
        super.tearDown()

        mockNetworkService.reset()
    }

    func testTrackState_sendsEdgeExperienceEvent() {
        mockNetworkService.setExpectationForNetworkRequest(url: edgeInteractEndpoint, httpMethod: .post, expectedCount: 1)

        MobileCore.track(state: "state name", data: ["key1": "value1", "&&c1": "propValue1"])

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations()
        let networkRequests = mockNetworkService.getNetworkRequestsWith(url: edgeInteractEndpoint, httpMethod: .post)
        XCTAssertEqual(1, networkRequests.count)

        let expectedJSON = """
            {
              "events": [
              {
                "data": {
                  "__adobe": {
                    "analytics": {
                      "pageName": "state name",
                      "c1": "propValue1",
                      "contextdata": {
                        "key1": "value1"
                      }
                    }
                  }
                },
                "xdm": {
                  "_id": "STRING_TYPE",
                  "eventType": "analytics.track",
                  "timestamp": "STRING_TYPE"
                }
              }
              ]
            }
        """

        assertExactMatch(
            expected: getAnyCodable(expectedJSON)!,
            actual: getAnyCodable(networkRequests[0]),
            typeMatchPaths: ["events[0].xdm._id", "events[0].xdm.timestamp"])
    }

    func testTrackAction_sendsCorrectRequestEvent() {
        mockNetworkService.setExpectationForNetworkRequest(url: edgeInteractEndpoint, httpMethod: .post, expectedCount: 1)

        MobileCore.track(action: "action name", data: ["key1": "value1", "&&c1": "propValue1"])

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations()
        let networkRequests = mockNetworkService.getNetworkRequestsWith(url: edgeInteractEndpoint, httpMethod: .post)
        XCTAssertEqual(1, networkRequests.count)

        let expectedJSON = """
            {
              "events": [
              {
                "data": {
                  "__adobe": {
                    "analytics": {
                      "linkName": "action name",
                      "linkType": "other",
                      "c1": "propValue1",
                      "contextdata": {
                        "key1": "value1"
                      }
                    }
                  }
                },
                "xdm": {
                  "_id": "STRING_TYPE",
                  "eventType": "analytics.track",
                  "timestamp": "STRING_TYPE"
                }
              }
              ]
            }
        """

        assertExactMatch(
            expected: getAnyCodable(expectedJSON)!,
            actual: getAnyCodable(networkRequests[0]),
            typeMatchPaths: ["events[0].xdm._id", "events[0].xdm.timestamp"])
    }

    func testRulesEngineResponse_sendsCorrectRequestEvent() {
        updateConfigurationWithRules(localRulesName: "rules_analytics")
        resetTestExpectations()

        mockNetworkService.setExpectationForNetworkRequest(url: edgeInteractEndpoint, httpMethod: .post, expectedCount: 1)

        MobileCore.collectPii(["key": "value"]) // triggers Analytics rule

        // verify
        mockNetworkService.assertAllNetworkRequestExpectations()
        let networkRequests = mockNetworkService.getNetworkRequestsWith(url: edgeInteractEndpoint, httpMethod: .post)
        XCTAssertEqual(1, networkRequests.count)

        // Data is defined in the rule, not from the dispatched PII event
        let expectedJSON = """
            {
              "events": [
              {
                "data": {
                  "__adobe": {
                    "analytics": {
                      "linkName": "Rule Action",
                      "linkType": "other",
                      "pageName": "Rule State",
                      "contextdata": {
                        "testKey": "testValue"
                      }
                    }
                  }
                },
                "xdm": {
                  "_id": "STRING_TYPE",
                  "eventType": "analytics.track",
                  "timestamp": "STRING_TYPE"
                }
              }
              ]
            }
        """

        assertExactMatch(
            expected: getAnyCodable(expectedJSON)!,
            actual: getAnyCodable(networkRequests[0]),
            typeMatchPaths: ["events[0].xdm._id", "events[0].xdm.timestamp"])
    }

    /// Helper function to update configuration with rules URL and mock response with a local zip file.
    /// - Parameter localRulesName: name of bundled file with rules definition without '.zip' extension
    private func updateConfigurationWithRules(localRulesName: String) {
        let filePath = Bundle(for: type(of: self)).url(forResource: localRulesName, withExtension: ".zip")
        let data = try? Data(contentsOf: filePath!)

        let response = HTTPURLResponse(url: URL(string: "https://adobe.com")!, statusCode: 200, httpVersion: nil, headerFields: [:])
        let responseConnection = HttpConnection(data: data, response: response, error: nil)

        mockNetworkService.setMockResponse(url: "https://rules.com/\(localRulesName).zip", httpMethod: .get, responseConnection: responseConnection)
        mockNetworkService.setExpectationForNetworkRequest(url: "https://rules.com/\(localRulesName).zip", httpMethod: .get, expectedCount: 1)

        MobileCore.updateConfigurationWith(configDict: ["rules.url": "https://rules.com/\(localRulesName).zip"])

        mockNetworkService.assertAllNetworkRequestExpectations()
    }

}

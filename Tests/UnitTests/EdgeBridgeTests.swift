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
@testable import AEPEdgeBridge
import XCTest

class EdgeBridgeTests: XCTestCase {
    var mockRuntime: TestableExtensionRuntime!
    var edgeBridge: EdgeBridge!

    override func setUp() {
        mockRuntime = TestableExtensionRuntime()

        edgeBridge = EdgeBridge(runtime: mockRuntime)
        edgeBridge.onRegistered()
    }

    override func tearDown() {
        mockRuntime.resetDispatchedEventAndCreatedSharedStates()
    }

    func testReadyForEvent_genericTrackEvent_returnsTrue() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: nil)

        XCTAssertTrue(edgeBridge.readyForEvent(event))
    }

    func testReadyForEvent_rulesEngineResponseEvent_returnsTrue() {
        let event = Event(name: "Test Rule Engine Response",
                          type: EventType.rulesEngine,
                          source: EventSource.responseContent,
                          data: nil)

        XCTAssertTrue(edgeBridge.readyForEvent(event))
    }

    func testHandleTrackEvent_dispatchesEdgeRequestEvent() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "action": "Test Action",
                            "contextdata": [
                                "testKey": "testValue"
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)

        guard let dispatchedData = dispatchedEvent.data else {
            XCTFail("Dispatched event expected to have data but was nil.")
            return
        }

        let expectedData: [String: Any] = [
            "data": [
                "action": "Test Action",
                "contextdata": [
                    "testKey": "testValue"
                ]
            ],
            "xdm": [
                "timestamp": event.timestamp.getISO8601UTCDateWithMilliseconds(),
                "eventType": "analytics.track"
            ]
        ]

        assertEqual(expectedData, dispatchedData)
        XCTAssertEqual(event.id, dispatchedEvent.parentID)
    }

    func testHandleTrackEvent_withNilEventData_doesNotDispatchEvent() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: nil)

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testHandleTrackEvent_withEmptyEventData_doesNotDispatchEvent() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [:])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testHandleRulesEngineResponse_withTrackEvent_dispatchesEdgeRequestEvent() {
        let event = Event(name: "Test Rule Engine Response",
                          type: EventType.rulesEngine,
                          source: EventSource.responseContent,
                          data: [
                            "triggeredconsequence": [
                                "type": "an",
                                "id": "some value",
                                "detail": [
                                    "action": "Test Action",
                                    "contextdata": [
                                        "testKey": "testValue"
                                    ]
                                ]
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)

        guard let dispatchedData = dispatchedEvent.data else {
            XCTFail("Dispatched event expected to have data but was nil.")
            return
        }

        let expectedData: [String: Any] = [
            "data": [
                "action": "Test Action",
                "contextdata": [
                    "testKey": "testValue"
                ]
            ],
            "xdm": [
                "timestamp": event.timestamp.getISO8601UTCDateWithMilliseconds(),
                "eventType": "analytics.track"
            ]
        ]

        assertEqual(expectedData, dispatchedData)
        XCTAssertEqual(event.id, dispatchedEvent.parentID)
    }

    func testHandleRulesEngineResponse_withNilEventData_doesNotDispatchEvent() {
        let event = Event(name: "Test Rule Engine Response",
                          type: EventType.rulesEngine,
                          source: EventSource.responseContent,
                          data: nil)

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testHandleRulesEngineResponse_withEmptyEventData_doesNotDispatchEvent() {
        let event = Event(name: "Test Rule Engine Response",
                          type: EventType.rulesEngine,
                          source: EventSource.responseContent,
                          data: [:])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testHandleRulesEngineResponse_withoutTriggerConsequence_doesNotDispatchEvent() {
        let event = Event(name: "Test Rule Engine Response",
                          type: EventType.rulesEngine,
                          source: EventSource.responseContent,
                          data: [
                            "nottriggeredconsequence": [
                                "type": "an",
                                "id": "some value",
                                "detail": [
                                    "action": "Test Action",
                                    "contextdata": [
                                        "testKey": "testValue"
                                    ]
                                ]
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testHandleRulesEngineResponse_withTriggerConsequenceWrongType_doesNotDispatchEvent() {
        let event = Event(name: "Test Rule Engine Response",
                          type: EventType.rulesEngine,
                          source: EventSource.responseContent,
                          data: [
                            "triggeredconsequence": "i should be a dictionary"
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testHandleRulesEngineResponse_withoutConsequenceId_doesNotDispatchEvent() {
        let event = Event(name: "Test Rule Engine Response",
                          type: EventType.rulesEngine,
                          source: EventSource.responseContent,
                          data: [
                            "triggeredconsequence": [
                                "type": "an",
                                "detail": [
                                    "action": "Test Action",
                                    "contextdata": [
                                        "testKey": "testValue"
                                    ]
                                ]
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testHandleRulesEngineResponse_withConsequenceIdWrongType_doesNotDispatchEvent() {
        let event = Event(name: "Test Rule Engine Response",
                          type: EventType.rulesEngine,
                          source: EventSource.responseContent,
                          data: [
                            "triggeredconsequence": [
                                "type": "an",
                                "id": ["some id"], // should be type String
                                "detail": [
                                    "action": "Test Action",
                                    "contextdata": [
                                        "testKey": "testValue"
                                    ]
                                ]
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testHandleRulesEngineResponse_withWrongConsequenceType_doesNotDispatchEvent() {
        let event = Event(name: "Test Rule Engine Response",
                          type: EventType.rulesEngine,
                          source: EventSource.responseContent,
                          data: [
                            "triggeredconsequence": [
                                "type": "md",
                                "id": "some value",
                                "detail": [
                                    "action": "Test Action",
                                    "contextdata": [
                                        "testKey": "testValue"
                                    ]
                                ]
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testHandleRulesEngineResponse_withoutConsequenceType_doesNotDispatchEvent() {
        let event = Event(name: "Test Rule Engine Response",
                          type: EventType.rulesEngine,
                          source: EventSource.responseContent,
                          data: [
                            "triggeredconsequence": [
                                "id": "some value",
                                "detail": [
                                    "action": "Test Action",
                                    "contextdata": [
                                        "testKey": "testValue"
                                    ]
                                ]
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testHandleRulesEngineResponse_withConsequenceTypeWrongType_doesNotDispatchEvent() {
        let event = Event(name: "Test Rule Engine Response",
                          type: EventType.rulesEngine,
                          source: EventSource.responseContent,
                          data: [
                            "triggeredconsequence": [
                                "type": ["an"], // should be type String
                                "id": "some value",
                                "detail": [
                                    "action": "Test Action",
                                    "contextdata": [
                                        "testKey": "testValue"
                                    ]
                                ]
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testHandleRulesEngineResponse_withoutConsequenceDetail_doesNotDispatchEvent() {
        let event = Event(name: "Test Rule Engine Response",
                          type: EventType.rulesEngine,
                          source: EventSource.responseContent,
                          data: [
                            "triggeredconsequence": [
                                "type": "an",
                                "id": "some value"
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testHandleRulesEngineResponse_withNilConsequenceDetail_doesNotDispatchEvent() {
        let event = Event(name: "Test Rule Engine Response",
                          type: EventType.rulesEngine,
                          source: EventSource.responseContent,
                          data: [
                            "triggeredconsequence": [
                                "type": "an",
                                "id": "some value",
                                "detail": nil
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testHandleRulesEngineResponse_withEmptyConsequenceDetail_doesNotDispatchEvent() {
        let event = Event(name: "Test Rule Engine Response",
                          type: EventType.rulesEngine,
                          source: EventSource.responseContent,
                          data: [
                            "triggeredconsequence": [
                                "type": "an",
                                "id": "some value",
                                "detail": [:]
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    func testHandleRulesEngineResponse_withConsequenceDetailWrongType_doesNotDispatchEvent() {
        let event = Event(name: "Test Rule Engine Response",
                          type: EventType.rulesEngine,
                          source: EventSource.responseContent,
                          data: [
                            "triggeredconsequence": [
                                "type": "an",
                                "id": "some value",
                                "detail": "wrong type" // should be type Dictionary
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }
}

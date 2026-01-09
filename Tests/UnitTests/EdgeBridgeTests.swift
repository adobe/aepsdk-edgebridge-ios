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
import AEPServices
import AEPTestUtils
import XCTest

// swiftlint:disable type_body_length
class EdgeBridgeTests: XCTestCase, AnyCodableAsserts {
    var mockRuntime: TestableExtensionRuntime!
    var edgeBridge: EdgeBridge!

    var fakeSystemInfoService = FakeSystemInfoService()

    var applicationIdentifier = "appName 1.0 (2)"

    override func setUp() {
        fakeSystemInfoService.applicationName = "appName"
        fakeSystemInfoService.applicationVersionNumber = "1.0"
        fakeSystemInfoService.applicationBuildNumber = "2"

        ServiceProvider.shared.systemInfoService = fakeSystemInfoService

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

    func testHandleTrackEvent_withActionField_dispatchesEdgeRequestEvent() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "action": "action name"
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(event.id, dispatchedEvent.parentID)
        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)

        let expectedJSON = """
            {
              "data": {
                "__adobe": {
                  "analytics": {
                    "linkName": "action name",
                    "linkType": "other",
                    "cp": "foreground",
                    "contextData": {
                      "a.AppID": "\(applicationIdentifier)"
                    }
                  }
                }
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: expectedJSON, actual: dispatchedEvent)
    }

    func testHandleTrackEvent_withActionFieldWithEmptyValue_dispatchesEdgeRequestEvent_withoutAction() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "action": "",
                            "contextdata": [
                                "&&c1": "propValue1"
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(event.id, dispatchedEvent.parentID)
        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)

        let expectedJSON = """
            {
              "data": {
                "__adobe": {
                  "analytics": {
                    "c1": "propValue1",
                    "cp": "foreground",
                    "contextData": {
                      "a.AppID": "\(applicationIdentifier)"
                    }
                  }
                }
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: expectedJSON, actual: dispatchedEvent)
    }

    func testHandleTrackEvent_withActionFieldWithNilValue_dispatchesEdgeRequestEvent_withoutAction() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "action": NSNull(),
                            "contextdata": [
                                "&&c1": "propValue1"
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(event.id, dispatchedEvent.parentID)
        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)

        let expectedJSON = """
            {
              "data": {
                "__adobe": {
                  "analytics": {
                    "c1": "propValue1",
                    "cp": "foreground",
                    "contextData": {
                      "a.AppID": "\(applicationIdentifier)"
                    }
                  }
                }
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: expectedJSON, actual: dispatchedEvent)
    }

    func testHandleTrackEvent_withStateField_dispatchesEdgeRequestEvent() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "state": "state name"
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(event.id, dispatchedEvent.parentID)
        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)

        let expectedJSON = """
            {
              "data": {
                "__adobe": {
                  "analytics": {
                    "pageName": "state name",
                    "cp": "foreground",
                    "contextData": {
                      "a.AppID": "\(applicationIdentifier)"
                    }
                  }
                }
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: expectedJSON, actual: dispatchedEvent)
    }

    func testHandleTrackEvent_withStateFieldWithNilValue_dispatchesEdgeRequestEvent_withoutState() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "state": NSNull(),
                            "contextdata": [
                                "&&c1": "propValue1"
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(event.id, dispatchedEvent.parentID)
        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)

        let expectedJSON = """
            {
              "data": {
                "__adobe": {
                  "analytics": {
                    "c1": "propValue1",
                    "cp": "foreground",
                    "contextData": {
                      "a.AppID": "\(applicationIdentifier)"
                    }
                  }
                }
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: expectedJSON, actual: dispatchedEvent)
    }

    func testHandleTrackEvent_withStateFieldWithEmptyValue_dispatchesEdgeRequestEvent_withoutState() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "state": "",
                            "contextdata": [
                                "&&c1": "propValue1"
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(event.id, dispatchedEvent.parentID)
        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)

        let expectedJSON = """
            {
              "data": {
                "__adobe": {
                  "analytics": {
                    "c1": "propValue1",
                    "cp": "foreground",
                    "contextData": {
                      "a.AppID": "\(applicationIdentifier)"
                    }
                  }
                }
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: expectedJSON, actual: dispatchedEvent)
    }

    func testHandleTrackEvent_withContextDataFieldUsingReservedPrefix_dispatchesEdgeRequestEvent() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "contextdata": [
                                "&&c1": "propValue1"
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(event.id, dispatchedEvent.parentID)
        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)

        let expectedJSON = """
            {
              "data": {
                "__adobe": {
                  "analytics": {
                    "c1": "propValue1",
                    "cp": "foreground",
                    "contextData": {
                      "a.AppID": "\(applicationIdentifier)"
                    }
                  }
                }
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: expectedJSON, actual: dispatchedEvent)
    }

    func testHandleTrackEvent_withContextDataNotUsingReservedPrefix_dispatchesEdgeRequestEvent() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "contextdata": [
                                "key1": "value1"
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(event.id, dispatchedEvent.parentID)
        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)

        let expectedJSON = """
            {
              "data": {
                "__adobe": {
                  "analytics": {
                    "cp": "foreground",
                    "contextData": {
                      "key1": "value1",
                      "a.AppID": "\(applicationIdentifier)"
                    }
                  }
                }
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: expectedJSON, actual: dispatchedEvent)
    }

    func testHandleTrackEvent_withDataField_dispatchesEdgeRequestEvent() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "key2": "value2"
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(event.id, dispatchedEvent.parentID)
        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)

        let expectedJSON = """
            {
              "data": {
                "key2": "value2"
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: expectedJSON, actual: dispatchedEvent)
    }

    func testHandleTrackEvent_trackAction_dispatchesEdgeRequestEvent() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "action": "action name",
                            "key2": "value2",
                            "contextdata": [
                                "&&events": "event1,event2,event3,event4,event12,event13",
                                "&&products": ";product1;1;5.99;event12=5.99;evar5=merchEvar5,;product2;2;10.99;event13=6;eVar6=mercheVar6",
                                "&&c1": "propValue1",
                                "&&cc": "USD",
                                "key1": "value1"
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(event.id, dispatchedEvent.parentID)
        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)

        let expectedJSON = """
            {
              "data": {
                "__adobe": {
                  "analytics": {
                    "linkName": "action name",
                    "linkType": "other",
                    "events": "event1,event2,event3,event4,event12,event13",
                    "products": ";product1;1;5.99;event12=5.99;evar5=merchEvar5,;product2;2;10.99;event13=6;eVar6=mercheVar6",
                    "c1": "propValue1",
                    "cc": "USD",
                    "cp": "foreground",
                    "contextData": {
                      "key1": "value1",
                      "a.AppID": "\(applicationIdentifier)"
                    }
                  }
                },
                "key2": "value2"
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: expectedJSON, actual: dispatchedEvent)
    }

    func testHandleTrackEvent_trackState_dispatchesEdgeRequestEvent() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "state": "state name",
                            "key2": "value2",
                            "contextdata": [
                                "&&events": "event1,event2,event3,event4,event12,event13",
                                "&&c1": "propValue1",
                                "&&v1": "evarValue1",
                                "key1": "value1"
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(event.id, dispatchedEvent.parentID)
        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)

        let expectedJSON = """
            {
              "data": {
                "__adobe": {
                  "analytics": {
                    "pageName": "state name",
                    "events": "event1,event2,event3,event4,event12,event13",
                    "c1": "propValue1",
                    "v1": "evarValue1",
                    "cp": "foreground",
                    "contextData": {
                      "key1": "value1",
                      "a.AppID": "\(applicationIdentifier)"
                    }
                  }
                },
                "key2": "value2"
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: expectedJSON, actual: dispatchedEvent)
    }

    // Test event still dispatched if request contains data but no 'track' data.
    // Additional data may be added through Rules.
    func testHandleTrackEvent_hasDataButNoTrackData_dispatchesEdgeRequestEvent() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "key": "value"
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(event.id, dispatchedEvent.parentID)
        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)

        let expectedJSON = """
            {
              "data": {
                "key": "value"
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: expectedJSON, actual: dispatchedEvent)
    }

    // Tests event is not dispatched if no track data is available
    func testHandleTrackEvent_withNoMappedData_doesNotDispatchEvent() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "state": "",
                            "action": "",
                            "contextdata": []
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    // Tests event is not dispatched if no track data is available
    func testHandleTrackEvent_withNoMappedData_nilValues_doesNotDispatchEvent() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "state": NSNull(),
                            "action": NSNull(),
                            "contextdata": NSNull()
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(0, mockRuntime.dispatchedEvents.count)
    }

    // Test using prefixed key of '&&' is not included in request as it produces an empty string key
    func testHandleTrackEvent_withContextDataFieldUsingReservedPrefix_emptyKeyName_dispatchesEdgeRequestEvent_emptyKeysIgnored() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "contextdata": [
                                "&&c1": "propValue",
                                "&&": "emptyKey"
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(event.id, dispatchedEvent.parentID)
        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)

        let expectedJSON = """
            {
              "data": {
                "__adobe": {
                  "analytics": {
                    "c1": "propValue",
                    "cp": "foreground",
                    "contextData": {
                      "a.AppID": "\(applicationIdentifier)"
                    }
                  }
                }
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: expectedJSON, actual: dispatchedEvent)
    }

    func testHandleTrackEvent_withContextDataFieldUsingReservedPrefix_emptyValue_dispatchesEdgeRequestEvent_emptyValuesAllowed() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "contextdata": [
                                "&&c1": "propValue",
                                "&&v1": ""
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(event.id, dispatchedEvent.parentID)
        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)

        let expectedJSON = """
            {
              "data": {
                "__adobe": {
                  "analytics": {
                    "c1": "propValue",
                    "v1": "",
                    "cp": "foreground",
                    "contextData": {
                      "a.AppID": "\(applicationIdentifier)"
                    }
                  }
                }
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: expectedJSON, actual: dispatchedEvent)
    }

    func testHandleTrackEvent_withContextDataFieldUsingReservedPrefix_nilValue_dispatchesEdgeRequestEvent_nilValuesIgnored() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "contextdata": [
                                "&&c1": "propValue",
                                "&&v1": nil
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(event.id, dispatchedEvent.parentID)
        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)

        let expectedJSON = """
            {
              "data": {
                "__adobe": {
                  "analytics": {
                    "c1": "propValue",
                    "cp": "foreground",
                    "contextData": {
                      "a.AppID": "\(applicationIdentifier)"
                    }
                  }
                }
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: expectedJSON, actual: dispatchedEvent)
    }

    // Test empty string keys are not allowed
    func testHandleTrackEvent_withContextDataField_emptyKeyName_dispatchesEdgeRequestEvent_emptyKeysIgnored() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "contextdata": [
                                "key": "value",
                                "": "valueEmptyKey"
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(event.id, dispatchedEvent.parentID)
        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)

        let expectedJSON = """
            {
              "data": {
                "__adobe": {
                  "analytics": {
                    "cp": "foreground",
                    "contextData": {
                      "key": "value",
                      "a.AppID": "\(applicationIdentifier)"
                    }
                  }
                }
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: expectedJSON, actual: dispatchedEvent)
    }

    // Public track APIs define context data as [String: Any] which do not allow null keys.
    // However, an Event may still have nil keys if set inside a dictionary cause "contextdata" parsing to fail
    func testHandleTrackEvent_withContextDataField_withNilKeyName_dispatchesEdgeRequestEvent_withoutContextData() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "state": "test state",
                            "contextdata": [
                                "key": "value",
                                nil: "valueNilKey"
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(event.id, dispatchedEvent.parentID)
        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)

        let expectedJSON = """
            {
              "data": {
                "__adobe": {
                  "analytics": {
                    "pageName": "test state",
                    "cp": "foreground",
                    "contextData": {
                      "a.AppID": "\(applicationIdentifier)"
                    }
                  }
                }
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: expectedJSON, actual: dispatchedEvent)
    }

    // Test empty string values are allowed
    func testHandleTrackEvent_withContextDataField_emptyValue_dispatchesEdgeRequestEvent_emptyValuesAllowed() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "contextdata": [
                                "emptyValue": ""
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(event.id, dispatchedEvent.parentID)
        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)

        let expectedJSON = """
            {
              "data": {
                "__adobe": {
                  "analytics": {
                    "cp": "foreground",
                    "contextData": {
                      "emptyValue": "",
                      "a.AppID": "\(applicationIdentifier)"
                    }
                  }
                }
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: expectedJSON, actual: dispatchedEvent)
    }

    func testHandleTrackEvent_withContextDataField_nilValue_dispatchesEdgeRequestEvent_nilValuesIgnored() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "contextdata": [
                                "key": "value",
                                "nilValue": nil
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(event.id, dispatchedEvent.parentID)
        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)

        let expectedJSON = """
            {
              "data": {
                "__adobe": {
                  "analytics": {
                    "cp": "foreground",
                    "contextData": {
                      "key": "value",
                      "a.AppID": "\(applicationIdentifier)"
                    }
                  }
                }
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: expectedJSON, actual: dispatchedEvent)
    }

    func testHandleTrackEvent_withReservedPrefix_onlyRemovesPrefix_dispatchesEdgeRequestEvent() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "contextdata": [
                                "&&": "value1",
                                "&&&": "value2",
                                "&&&&": "value3",
                                "&&1": "value4",
                                "&&a": "value5",
                                "&& ": "value6",
                                "&&-": "value7",
                                "&&=": "value8",
                                "&&\\": "value9",
                                "&&.": "value10",
                                "&&?": "value11",
                                "&&\n": "value12"
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(event.id, dispatchedEvent.parentID)
        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)

        let expectedJSON = """
            {
              "data": {
                "__adobe": {
                  "analytics": {
                    "&": "value2",
                    "&&": "value3",
                    "1": "value4",
                    "a": "value5",
                    " ": "value6",
                    "-": "value7",
                    "=": "value8",
                    "\\\\": "value9",
                    ".": "value10",
                    "?": "value11",
                    "\\n": "value12",
                    "cp": "foreground",
                    "contextData": {
                      "a.AppID": "\(applicationIdentifier)"
                    }
                  }
                }
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: expectedJSON, actual: dispatchedEvent)
    }

    func testHandleTrackEvent_withCharacterBeforeReservedCharacters_dispatchesEdgeRequestEvent() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "contextdata": [
                                "1&&": "value1",
                                "a&&": "value2",
                                " &&": "value3",
                                "-&&": "value4",
                                "=&&": "value5",
                                "\\&&": "value6",
                                ".&&": "value7",
                                "?&&": "value8",
                                "\n&&": "value9"
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(event.id, dispatchedEvent.parentID)
        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)

        let expectedJSON = """
            {
              "data": {
                "__adobe": {
                  "analytics": {
                    "cp": "foreground",
                    "contextData": {
                      "1&&": "value1",
                      "a&&": "value2",
                      " &&": "value3",
                      "-&&": "value4",
                      "=&&": "value5",
                      "\\\\&&": "value6",
                      ".&&": "value7",
                      "?&&": "value8",
                      "\\n&&": "value9",
                      "a.AppID": "\(applicationIdentifier)"
                    }
                  }
                }
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: expectedJSON, actual: dispatchedEvent)
    }

    // Test context data values are cleaned such that only String, Number, and Character types are allowed
    func testHandleTrackEvent_withContextData_valuesOfWrongTypes_dispatchesEdgeRequestEvent_valuesOfWrongTypesDropped() {
        let char: Character = "\u{0041}"
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "contextdata": [
                                "keyString": "valueString",
                                "keyNumber": 5,
                                "keyCharacter": char,
                                "&&v1": "evar1",
                                "&&v2": 10,
                                "&&v3": char,
                                "keyDict": ["hello": "world"],
                                "keyArray": ["one", "two", "three"],
                                "keyObj": Event(name: "testing", type: EventType.genericTrack, source: EventSource.requestContent, data: [:]),
                                "&&events": ["event1", "event2"],
                                "&&c1": ["prop1": "propValue"]
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(event.id, dispatchedEvent.parentID)
        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)

        // Test data directly instead of using Test Utils / AnyCodable libs as Character types are not supported
        guard let dispatchedData = dispatchedEvent.data else {
            XCTFail("Dispatched event expected to have data but was nil.")
            return
        }

        let expectedData: [String: Any] = [
            "data": [
                "__adobe": [
                    "analytics": [
                        "v1": "evar1",
                        "v2": 10,
                        "v3": char,
                        "cp": "foreground",
                        "contextData": [
                            "keyString": "valueString",
                            "keyNumber": 5,
                            "keyCharacter": char,
                            "a.AppID": "\(applicationIdentifier)"
                        ]
                    ]
                ]
            ],
            "xdm": [
                "timestamp": event.timestamp.getISO8601UTCDateWithMilliseconds(),
                "eventType": "analytics.track"
            ]
        ]

        XCTAssertEqual(expectedData as NSObject, dispatchedData as NSObject)
    }

    // Test event still dispatched if request contains data but no 'track' data. Data is not modified.
    // Additional data may be added through Rules.
    func testHandleTrackEvent_hasDataButNoTrackData_dataIsNotModified_andDispatchesEdgeRequestEvent() {
        let dataDictionary: [String: Any?] = [
            "key": "value",
            "&&c1": "prop1",
            "keyEmptyValue": "",
            "keyNilValue": nil,
            "": "valueEmptyKey",
            "additionalData": [
                "key": "value",
                nil: "valueNilKey"
            ]
        ]

        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: dataDictionary as [String: Any]
        )

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(event.id, dispatchedEvent.parentID)
        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)

        // Test data directly instead of using Test Utils / AnyCodable libs as nil keys/values are not supported
        guard let dispatchedData = dispatchedEvent.data else {
            XCTFail("Dispatched event expected to have data but was nil.")
            return
        }

        let expectedData: [String: Any] = [
            "data": dataDictionary,
            "xdm": [
                "timestamp": event.timestamp.getISO8601UTCDateWithMilliseconds(),
                "eventType": "analytics.track"
            ]
        ]

        XCTAssertEqual(expectedData as NSObject, dispatchedData as NSObject)
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
        XCTAssertEqual(event.id, dispatchedEvent.parentID)
        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)

        let expectedJSON = """
            {
              "data": {
                "__adobe": {
                  "analytics": {
                    "linkName": "Test Action",
                    "linkType": "other",
                    "cp": "foreground",
                    "contextData": {
                      "testKey": "testValue",
                      "a.AppID": "\(applicationIdentifier)"
                    }
                  }
                }
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: expectedJSON, actual: dispatchedEvent)
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

    // MARK: AppID tests

    func testHandleTrackEvent_withApplicationIdentifier_dispatchesEdgeRequestEvent_withAppID() {
        fakeSystemInfoService.applicationName = "myApp"
        fakeSystemInfoService.applicationVersionNumber = "1.0"
        fakeSystemInfoService.applicationBuildNumber = "2"

        assertInDispatchedEvent(appId: "myApp 1.0 (2)", customerPerspective: "foreground")
    }

    func testHandleTrackEvent_withNilApplicationName_dispatchesEdgeRequestEvent_withAppID() {
        fakeSystemInfoService.applicationName = nil
        fakeSystemInfoService.applicationVersionNumber = "1.0"
        fakeSystemInfoService.applicationBuildNumber = "2"

        assertInDispatchedEvent(appId: "1.0 (2)", customerPerspective: "foreground")
    }

    func testHandleTrackEvent_withNilApplicationVersionNumber_dispatchesEdgeRequestEvent_withAppID() {
        fakeSystemInfoService.applicationName = "myApp"
        fakeSystemInfoService.applicationVersionNumber = nil
        fakeSystemInfoService.applicationBuildNumber = "2"

        assertInDispatchedEvent(appId: "myApp (2)", customerPerspective: "foreground")
    }

    func testHandleTrackEvent_withNilApplicationBuildNumber_dispatchesEdgeRequestEvent_withAppID() {
        fakeSystemInfoService.applicationName = "myApp"
        fakeSystemInfoService.applicationVersionNumber = "1.0"
        fakeSystemInfoService.applicationBuildNumber = nil

        assertInDispatchedEvent(appId: "myApp 1.0", customerPerspective: "foreground")
    }

    func testHandleTrackEvent_withNilApplicationIdentifier_dispatchesEdgeRequestEvent_withEmptyAppID() {
        fakeSystemInfoService.applicationName = nil
        fakeSystemInfoService.applicationVersionNumber = nil
        fakeSystemInfoService.applicationBuildNumber = nil

        assertInDispatchedEvent(appId: "", customerPerspective: "foreground")
    }

    // MARK: Customer Perspective tests

    func testHandleTrackEvent_withActiveApplicationState_dispatchesEdgeRequestEvent_withCustomerPerspectiveForeground() {
        var fakeHelper = FakeEdgeBridgeHelper()
        fakeHelper.applicationState = .active
        edgeBridge.bridgeHelper = fakeHelper

        assertInDispatchedEvent(appId: applicationIdentifier, customerPerspective: "foreground")
    }

    func testHandleTrackEvent_withBackgroundApplicationState_dispatchesEdgeRequestEvent_withCustomerPerspectiveBackground() {
        var fakeHelper = FakeEdgeBridgeHelper()
        fakeHelper.applicationState = .background
        edgeBridge.bridgeHelper = fakeHelper

        assertInDispatchedEvent(appId: applicationIdentifier, customerPerspective: "background")
    }

    func testHandleTrackEvent_withInactiveApplicationState_dispatchesEdgeRequestEvent_withCustomerPerspectiveForeground() {
        var fakeHelper = FakeEdgeBridgeHelper()
        fakeHelper.applicationState = .inactive
        edgeBridge.bridgeHelper = fakeHelper

        assertInDispatchedEvent(appId: applicationIdentifier, customerPerspective: "foreground")
    }

    func testHandleTrackEvent_withNilApplicationState_dispatchesEdgeRequestEvent_withCustomerPerspectiveForeground() {
        var fakeHelper = FakeEdgeBridgeHelper()
        fakeHelper.applicationState = nil
        edgeBridge.bridgeHelper = fakeHelper

        assertInDispatchedEvent(appId: applicationIdentifier, customerPerspective: "foreground")
    }

    // MARK: Helpers

    /// Asserts `appId` is the same as the `a.AppID` and `customerPerspective` is the same as the `cp` in the dispatched Edge event.
    /// - Parameters:
    ///  - appId: the full `a.AppID` as appears in the Edge event
    ///  - customerPerspective: the full customer perspective as appears in the Edge event
    private func assertInDispatchedEvent(appId: String, customerPerspective: String) {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "state": "state name"
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]
        XCTAssertEqual(event.id, dispatchedEvent.parentID)
        XCTAssertEqual(EventType.edge, dispatchedEvent.type)
        XCTAssertEqual(EventSource.requestContent, dispatchedEvent.source)

        let expectedJSON = """
            {
              "data": {
                "__adobe": {
                  "analytics": {
                    "pageName": "state name",
                    "cp": "\(customerPerspective)",
                    "contextData": {
                      "a.AppID": "\(appId)"
                    }
                  }
                }
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: expectedJSON, actual: dispatchedEvent)
    }

    func testHandleTrackEvent_withContextDataField_valueIsConcreteNonOptional() {
        let optionalString: String? = "stringValue"
        let optionalStringNil: String? = nil
        let optionalInt: Int? = 5
        let optionalIntNil: Int? = nil
        let optionalChar: Character? = "c"
        let optionalCharNil: Character? = nil

        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "contextdata": [
                                "optionalStringKey": optionalString as Any,
                                "optionalNilStringKey": optionalStringNil as Any,
                                "optionalIntKey": optionalInt as Any,
                                "optionalNilIntKey": optionalIntNil as Any,
                                "optionalCharKey": optionalChar as Any,
                                "optionalNilCharKey": optionalCharNil as Any,
                                "concreteStringKey": "stringValue",
                                "concreteIntKey": 9,
                                "concreteCharKey": "h"
                            ]
                          ])

        mockRuntime.simulateComingEvents(event)

        XCTAssertEqual(1, mockRuntime.dispatchedEvents.count)
        let dispatchedEvent = mockRuntime.dispatchedEvents[0]

        guard
            let dispatchedData = dispatchedEvent.data?["data"] as? [String: Any],
            let adobeDictionary = dispatchedData[EdgeBridgeConstants.AnalyticsKeys.ADOBE] as? [String: Any],
            let analyticsDictionary = adobeDictionary[EdgeBridgeConstants.AnalyticsKeys.ANALYTICS] as? [String: Any],
            let contextData = analyticsDictionary[EdgeBridgeConstants.AnalyticsKeys.CONTEXT_DATA] as? [String: Any]
        else {
            XCTFail("Expected context data to be populated for dispatched event.")
            return
        }

        // Verify expected key count, minus nil values
        // Six keys in test + a.AppID added by Bridge.
        XCTAssertEqual(7, contextData.count, "Expected 7 non-optional keys for context data: \(contextData.keys)")

        contextData.forEach { key, value in
            let mirror = Mirror(reflecting: value)
            XCTAssertNotEqual(mirror.displayStyle, .optional, "Expected concrete String for \(key), but value is optional: \(value)")
        }

        // Verify Optional nil value is filted out and not set in Event Data
        XCTAssertFalse(contextData.keys.contains("optionalNilStringKey"))
        XCTAssertFalse(contextData.keys.contains("optionalNilIntKey"))
        XCTAssertFalse(contextData.keys.contains("optionalNilCharKey"))
    }

}

struct FakeEdgeBridgeHelper: EdgeBridgeHelper {
    public var applicationState: UIApplication.State?
    func getApplicationState() -> UIApplication.State? {
        applicationState
    }
}
// swiftlint:enable type_body_length

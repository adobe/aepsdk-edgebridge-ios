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
import AEPTestUtils
import XCTest

// swiftlint:disable type_body_length
class EdgeBridgeTests: XCTestCase, AnyCodableAsserts {
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
                    "linkType": "other"
                  }
                }
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: getAnyCodable(expectedJSON)!, actual: getAnyCodable(dispatchedEvent))
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
                    "c1": "propValue1"
                  }
                }
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: getAnyCodable(expectedJSON)!, actual: getAnyCodable(dispatchedEvent))
    }

    func testHandleTrackEvent_withActionFieldWithNilValue_dispatchesEdgeRequestEvent_withoutAction() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "action": nil,
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
                    "c1": "propValue1"
                  }
                }
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: getAnyCodable(expectedJSON)!, actual: getAnyCodable(dispatchedEvent))
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
                    "pageName": "state name"
                  }
                }
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: getAnyCodable(expectedJSON)!, actual: getAnyCodable(dispatchedEvent))
    }

    func testHandleTrackEvent_withStateFieldWithNilValue_dispatchesEdgeRequestEvent_withoutState() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "state": nil,
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
                    "c1": "propValue1"
                  }
                }
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: getAnyCodable(expectedJSON)!, actual: getAnyCodable(dispatchedEvent))
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
                    "c1": "propValue1"
                  }
                }
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: getAnyCodable(expectedJSON)!, actual: getAnyCodable(dispatchedEvent))
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
                    "c1": "propValue1"
                  }
                }
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: getAnyCodable(expectedJSON)!, actual: getAnyCodable(dispatchedEvent))
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
                    "contextData": {
                      "key1": "value1"
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

        assertEqual(expected: getAnyCodable(expectedJSON)!, actual: getAnyCodable(dispatchedEvent))
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

        assertEqual(expected: getAnyCodable(expectedJSON)!, actual: getAnyCodable(dispatchedEvent))
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
                    "contextData": {
                      "key1": "value1"
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

        assertEqual(expected: getAnyCodable(expectedJSON)!, actual: getAnyCodable(dispatchedEvent))
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
                    "contextData": {
                      "key1": "value1"
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

        assertEqual(expected: getAnyCodable(expectedJSON)!, actual: getAnyCodable(dispatchedEvent))
    }

    // Tests event is not dispatched is no track data is available
    func testHandleTrackEvent_withNoMappedData_doesNotDispatchEvent() {
        let event = Event(name: "Test Track Event",
                          type: EventType.genericTrack,
                          source: EventSource.requestContent,
                          data: [
                            "state": "",
                            "action": ""
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
                    "c1": "propValue"
                  }
                }
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: getAnyCodable(expectedJSON)!, actual: getAnyCodable(dispatchedEvent))
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
                    "contextData": {
                      "key": "value"
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

        assertEqual(expected: getAnyCodable(expectedJSON)!, actual: getAnyCodable(dispatchedEvent))
    }

    // Public track APIs define context data as [String: Any] which do not allow null keys.
    // However, if a null key is injected, extension will drop context data as it cannot be parsed
    func testHandleTrackEvent_withContextDataField_nilKeyName_dispatchesEdgeRequestEvent_contextDataDropped() {
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
                    "pageName": "test state"
                  }
                }
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: getAnyCodable(expectedJSON)!, actual: getAnyCodable(dispatchedEvent))
    }

    // Test empty string values are allowed
    func testHandleTrackEvent_withContextDataField_emptyValue_dispatchesEdgeRequestEvent() {
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
                    "contextData": {
                      "emptyValue": ""
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

        assertEqual(expected: getAnyCodable(expectedJSON)!, actual: getAnyCodable(dispatchedEvent))
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
                    "contextData": {
                      "key": "value"
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

        let codableExpected = getAnyCodable(expectedJSON)
        let codableDispatched = getAnyCodable(dispatchedEvent)

        assertEqual(expected: codableExpected, actual: codableDispatched)
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
                    "\\n": "value12"
                  }
                }
              },
              "xdm": {
                "timestamp": "\(event.timestamp.getISO8601UTCDateWithMilliseconds())",
                "eventType": "analytics.track"
              }
            }
        """

        assertEqual(expected: getAnyCodable(expectedJSON)!, actual: getAnyCodable(dispatchedEvent))
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
                    "contextData": {
                      "1&&": "value1",
                      "a&&": "value2",
                      " &&": "value3",
                      "-&&": "value4",
                      "=&&": "value5",
                      "\\\\&&": "value6",
                      ".&&": "value7",
                      "?&&": "value8",
                      "\\n&&": "value9"
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

        assertEqual(expected: getAnyCodable(expectedJSON)!, actual: getAnyCodable(dispatchedEvent))
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
                        "contextData": [
                            "keyString": "valueString",
                            "keyNumber": 5,
                            "keyCharacter": char
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
                    "contextData": {
                      "testKey": "testValue"
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

        assertEqual(expected: getAnyCodable(expectedJSON), actual: getAnyCodable(dispatchedEvent))
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

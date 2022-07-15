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
import AEPServices
import Foundation



struct TypeResult: CustomStringConvertible, Equatable {
    static func == (lhs: TypeResult, rhs: TypeResult) -> Bool {
        if lhs.unwrappedType == rhs.unwrappedType && lhs.isOptional == rhs.isOptional {
            return true
        }
        else {
            return false
        }
    }
    
    var isOptional: Bool
    var unwrappedType: Any.Type
    
    public var description: String { return "\(unwrappedType)" }
}

@objc(AEPMobileEdgeBridge)
public class EdgeBridge: NSObject, Extension {

    public let name = EdgeBridgeConstants.EXTENSION_NAME
    public let friendlyName = EdgeBridgeConstants.FRIENDLY_NAME
    public static let extensionVersion = EdgeBridgeConstants.EXTENSION_VERSION
    public let metadata: [String: String]? = nil
    public let runtime: ExtensionRuntime

    static private var contextDataStore: [[String:Any]] = []
    static private var shouldCaptureContextData: Bool = false
    
    public required init?(runtime: ExtensionRuntime) {
        self.runtime = runtime
        super.init()
    }

    public func onRegistered() {
        registerListener(type: EventType.genericTrack,
                         source: EventSource.requestContent,
                         listener: handleTrackRequest)

        registerListener(type: EventType.rulesEngine,
                         source: EventSource.responseContent,
                         listener: handleRuleEngineResponse)
    }

    public func onUnregistered() {}

    /// Called before each `Event` processed by this extension
    /// - Parameter event: event that will be processed next
    /// - Returns: always returns true
    public func readyForEvent(_ event: Event) -> Bool {
        return true
    }
    
    // method that starts context data tracking
        // intercept context data from trackAction/State
        // store in some in-memory datastore
    // probably hook into the existing track handling flow, copying the data into a local data store
    public static func startContextDataCaptureSession() {
        shouldCaptureContextData = true
        // clear existing data store
        contextDataStore = []
        
    }
    // method that stops context data tracking
        // also calls output method after tracking finished
    public static func stopContextDataCaptureSession() {
        shouldCaptureContextData = false
        EdgeBridge.outputCapturedContextData(withMerge: false)
    }
    // method that outputs current context data tracked
        // arg that performs best guess/effort combination of dictionaries
        // format is the json that is expected in the edge bridge web ui
    public static func outputCapturedContextData(withMerge: Bool) {
        if withMerge {
            
        }
        for dictionary in EdgeBridge.contextDataStore {
            for (key, value) in dictionary {
                print("Key: \(key)")
                EdgeBridge.checkTypes(valueA: value, valueB: nil)
            }
        }
        // its not that you have to flatten existing structures, its that you have to apply the same merger alg to nested hierarchies
        if let jsonData = try? JSONSerialization.data(withJSONObject: EdgeBridge.contextDataStore, options: .prettyPrinted) {
            print(String(decoding: jsonData, as: UTF8.self))
        } else {
            print("json data malformed")
        }
    }
    
    private func getClassName(value: Any) -> String {
        return "\(type(of: value))"
    }
    private func mergeDictionaries(dictionaryA: [String:Any], dictionaryB: [String:Any]) {
        // for any two dictionaries, apply the merge algorithm
        // toggles for merge options:
        // - case sensitivity
        // - value type conflicts
        // keyname : value type class names
        var valueTypeConflicts: [String:Set<String>] = [:]
        var keysA = dictionaryA.keys
        for (key,value) in dictionaryB {
            keysA.contains(key)
            
            if let keyCaseInsensitive = dictionaryA.keys.first(where: { $0.caseInsensitiveCompare(key) == .orderedSame }) {
                
            }
            //
        }
    }
    
    private static func getClassName(value: Any) -> String {
        return "\(type(of: value))"
    }
    
    private static func checkTypes(valueA: Any?, valueB: Any?) -> (isValueTypeSame: Bool, typeResultA: TypeResult, typeResultB: TypeResult) {
        // Reliance on the string conversion of a given type?
        // for some reason passing the value to a function re-anonymizes the type
        var typeResultA = TypeResult(isOptional: false, unwrappedType: Any.Type.self)
        var typeResultB = TypeResult(isOptional: false, unwrappedType: Any.Type.self)
        
        // Value A
        print(getClassName(value: valueA))
        if let valueA = valueA {
            // Optional type unwrapping
            if let optional = valueA as? OptionalProtocol {
                print(optional.wrappedType())
                typeResultA.unwrappedType = optional.wrappedType()
                typeResultA.isOptional = true
            }
            // Non-optional type
            else {
                typeResultA.unwrappedType = type(of: valueA)
            }
        }
        else {
            if let optional = valueA as? OptionalProtocol {
                print(optional.wrappedType())
                typeResultA.unwrappedType = optional.wrappedType()
                typeResultA.isOptional = true
            }
        }
        
        
        // Value B
        print(getClassName(value: valueB))
        if let valueB = valueB {
            if let optional = valueB as? OptionalProtocol {
                print(optional.wrappedType())
                typeResultB.unwrappedType = optional.wrappedType()
                typeResultB.isOptional = true
            }
            else {
                typeResultB.unwrappedType = type(of: valueB)
            }
        }
        else {
            if let optional = valueB as? OptionalProtocol {
                print(optional.wrappedType())
                typeResultB.unwrappedType = optional.wrappedType()
                typeResultB.isOptional = true
            }
        }
        
        print("typeA: \(typeResultA)")
        print("typeB: \(typeResultB)")
        print("typeA == typeB: \(typeResultA == typeResultB)")
        // what were the keys, what value were they tied to
        // keys value types mismatched or optional vs nonoptional
        return (isValueTypeSame: typeResultA == typeResultB, typeResultA: typeResultA, typeResultB: typeResultB)
    }
    
    private func handleCaptureContextData(data: [String:Any]) {
        // add to existing list
        EdgeBridge.contextDataStore.append(data)
    }
    
    /// Handles generic Analytics track events coming from the public APIs.
    /// - Parameter event: the generic track request event
    private func handleTrackRequest(_ event: Event) {
        guard let eventData = event.data, !eventData.isEmpty else {
            Log.debug(label: EdgeBridgeConstants.LOG_TAG, "Unable to handle track request event with id '\(event.id.uuidString)': event data is missing or empty.")
            return
        }

        dispatchTrackRequest(data: eventData, timestamp: event.timestamp)
    }

    ///  Handles Analytics track events generated by a rule consequence.
    ///  - Parameter event: the rules engine response event
    private func handleRuleEngineResponse(_ event: Event) {
        if event.data == nil {
            Log.trace(label: EdgeBridgeConstants.LOG_TAG, "Ignoring Rule Engine response event with id '\(event.id.uuidString)': event data is missing.")
            return
        }
        guard let consequence = event.data?["triggeredconsequence"] as? [String: Any] else {
            Log.trace(label: EdgeBridgeConstants.LOG_TAG, "Ignoring Rule Engine response event with id '\(event.id.uuidString)': consequence data is missing.")
            return
        }
        
        guard let consequenceType = consequence["type"] as? String, consequenceType == "an" else {
            return
        }
        if consequence["id"] as? String == nil {
            Log.trace(label: EdgeBridgeConstants.LOG_TAG, "Ignoring Rule Engine response event with id '\(event.id.uuidString)': consequence id is missing.")
            return
        }

        guard let consequenceDetail = consequence["detail"] as? [String: Any], !consequenceDetail.isEmpty else {
            Log.trace(label: EdgeBridgeConstants.LOG_TAG, "Ignoring Rule Engine response event with id '\(event.id.uuidString)': consequence detail is missing or empty.")
            return
        }

        dispatchTrackRequest(data: consequenceDetail, timestamp: event.timestamp)
    }

    /// Helper to create and dispatch an experience event.
    /// - Parameters:
    ///   - data: dictionary containing free-form data to send to Edge Network
    ///   - timestamp: timestamp of Event
    private func dispatchTrackRequest(data: [String: Any], timestamp: Date) {
        let xdmEventData: [String: Any] = [
            "data": data,
            "xdm": [
                "timestamp": timestamp.getISO8601UTCDateWithMilliseconds(),
                "eventType": EdgeBridgeConstants.JsonValues.EVENT_TYPE
            ]
        ]

        let xdmEvent = Event(name: EdgeBridgeConstants.EventNames.EDGE_BRIDGE_REQUEST,
                             type: EventType.edge,
                             source: EventSource.requestContent,
                             data: xdmEventData)

        runtime.dispatch(event: xdmEvent)
        if EdgeBridge.shouldCaptureContextData {
            handleCaptureContextData(data: data)
        }
    }
}

fileprivate protocol OptionalProtocol {
    func wrappedType() -> Any.Type
}

extension Optional : OptionalProtocol {
    func wrappedType() -> Any.Type {
        return Wrapped.self
    }
}

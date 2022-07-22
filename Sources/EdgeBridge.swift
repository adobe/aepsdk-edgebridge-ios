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



fileprivate struct TypeResult: CustomStringConvertible, Equatable {
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
    
    public var description: String { return "\(isOptional ? "Optional " : "")\(unwrappedType)" }
}

fileprivate struct KeySet {
    var eventID: UUID
    var originalKeyValue: String
    var typeResult: TypeResult
    var keypath: [String]
}

fileprivate struct MergeResult {
    
    let isCaseSensitive: Bool
    // the ids of the dictionaries that were merged to arrive at this result, appended in the order they were merged
    var ids: [UUID]
    // the dictionary that stores the result of the merge
    var dictionary: [String:Any]
    // Mapping of key to KeySet (hierarhcy doesnt matter since it is covered by grouping by keypath)
    var keySet: [String:[KeySet]]
    
    init(event: Event, isCaseSensitive: Bool) {
        self.isCaseSensitive = isCaseSensitive
        self.ids = [event.id]
        self.dictionary = event.data ?? [:]
        self.keySet = EdgeBridge.extractKeySet(dictionary: self.dictionary, eventID: event.id, isCaseSensitive: isCaseSensitive, keypath: [])
    }
    
    
}

@objc(AEPMobileEdgeBridge)
public class EdgeBridge: NSObject, Extension {

    public let name = EdgeBridgeConstants.EXTENSION_NAME
    public let friendlyName = EdgeBridgeConstants.FRIENDLY_NAME
    public static let extensionVersion = EdgeBridgeConstants.EXTENSION_VERSION
    public let metadata: [String: String]? = nil
    public let runtime: ExtensionRuntime

    static var contextDataStore: [Event] = []
    static private var shouldCaptureContextData: Bool = false
    static private var isKeyMatchCaseInsensitive: Bool = false
    
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
    public static func startContextDataCaptureSession(isKeyMatchCaseInsensitive: Bool) {
        shouldCaptureContextData = true
        self.isKeyMatchCaseInsensitive = isKeyMatchCaseInsensitive
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
            // initialize merge result
                // nested dictionaries should be sent into same function but with keypath (that is the keymatchset is a flat record)
                // arrays?? and if things should be compared??
            // start merging next events into result
            guard let firstEvent = EdgeBridge.contextDataStore.first else {
                print("No events to merge!")
                return
            }
            var mergeResult = MergeResult(event: firstEvent, isCaseSensitive: false)
            if EdgeBridge.contextDataStore.count > 1 {
                for i in 1..<EdgeBridge.contextDataStore.count {
                    mergeResult = mergeEvents(mergeResult: mergeResult, eventToMerge: EdgeBridge.contextDataStore[i])
                }
            }
            print("============== Merge Result =================")
            for (key, value) in mergeResult.keySet {
                // TEST: debug output for key and all keysets
//                print("- - Key: \(key) - -")
//                for record in value {
//                    print(record)
//                }
                // END TEST: debug output
                
                // for each key, group by keypath
                var keysets = value
                
                while !keysets.isEmpty {
                    guard let keypath = keysets.first?.keypath else { break }
                    let matchingKeysets = keysets.filter({ $0.keypath == keypath })
                    keysets.removeAll(where: { $0.keypath == keypath })
                    if matchingKeysets.count <= 1 { continue }
                    // Check matching:
                    // original key value
                    
                    if !matchingKeysets.allSatisfy({ $0.originalKeyValue == matchingKeysets.first!.originalKeyValue }) {
                        print("Key string mismatch (keypath: \(keypath)): \(matchingKeysets.map({($0.eventID, $0.originalKeyValue)}))")
                    }
//                    else {
//                        print("All key values match: \(matchingKeysets.map({($0.eventID, $0.originalKeyValue)}))")
//                    }
                    // types and optional status
                    if !matchingKeysets.allSatisfy({ $0.typeResult == matchingKeysets.first!.typeResult }) {
                        print("Value type mismatch (keypath: \(keypath)): \(matchingKeysets.map({($0.eventID, $0.originalKeyValue, $0.typeResult)}))")
                    }
//                    else {
//                        print("All key value types match: \(matchingKeysets.map({($0.eventID, $0.typeResult)}))")
//                    }
                    
                }

            }
            
            print("------------- Merge Dictionary ----------------")
            if let jsonData = try? JSONSerialization.data(withJSONObject: mergeResult.dictionary, options: .prettyPrinted) {
                print(String(decoding: jsonData, as: UTF8.self))
            } else {
                print("json data malformed")
            }
        }
        for event in EdgeBridge.contextDataStore {
            guard let eventData = event.data else {
                continue
            }
            for (key, value) in eventData {
//                print("Key: \(key)")
                EdgeBridge.checkTypes(valueA: value, valueB: nil)
            }
        }
        // its not that you have to flatten existing structures, its that you have to apply the same merger alg to nested hierarchies
        print("Number of events captured: \(EdgeBridge.contextDataStore.count)")
        print("Event IDs: \(EdgeBridge.contextDataStore.map({$0.id}))")
        for event in EdgeBridge.contextDataStore {
            print(event.id)
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: event.data, options: .prettyPrinted) {
                print(String(decoding: jsonData, as: UTF8.self))
            } else {
                print("json data malformed")
            }
        }
        
    }
    
    // the key in the dictionary is what matching system will be used; that is case sensitivity transform is applied if required; original value is stored in keyset
    fileprivate static func extractKeySet(dictionary: [String:Any], eventID: UUID, isCaseSensitive: Bool, keypath: [String]) -> [String:[KeySet]] {
        var result: [String:[KeySet]] = [:]
        
        for (key, value) in dictionary {
            let finalKey = isCaseSensitive ? key : key.lowercased()
            let typeResult = checkType(value: value)
            let keySet = KeySet(eventID: eventID, originalKeyValue: key, typeResult: typeResult, keypath: keypath)
            if let record = result[finalKey] {
                result[finalKey]?.append(keySet)
            }
            else {
                result[finalKey] = [keySet]
            }
            if value is [String:Any] {
                guard let childDictionary = value as? [String:Any] else { continue }
                var childKeypath = keypath
                childKeypath.append(finalKey)
                result.merge(extractKeySet(dictionary: childDictionary, eventID: eventID, isCaseSensitive: isCaseSensitive, keypath: childKeypath), uniquingKeysWith: { lhs, rhs in
                    var result = lhs
                    result.append(contentsOf: rhs)
                    return result
                })
            }
        }
        return result
    }
    
    private func getClassName(value: Any) -> String {
        return "\(type(of: value))"
    }
    
    private static func mergeEvents(mergeResult: MergeResult, eventToMerge: Event) -> MergeResult {
        // for any two dictionaries, apply the merge algorithm
        // toggles for merge options:
        // - case sensitivity
        // - value type conflicts
        // keyname : value type class names
        var mergeResult = mergeResult
        let dictionaryToMerge = eventToMerge.data ?? [:]
        let keySetToMerge = extractKeySet(dictionary: dictionaryToMerge, eventID: eventToMerge.id, isCaseSensitive: mergeResult.isCaseSensitive, keypath: [])
        mergeResult.keySet.merge(keySetToMerge, uniquingKeysWith: { lhs, rhs in
            var result = lhs
            result.append(contentsOf: rhs)
            return result
        })
        for (key,value) in dictionaryToMerge {
            // just replace the value with the one, all value type collisions will be caught by the keysets
            if !mergeResult.isCaseSensitive {
                if let foundKey = mergeResult.dictionary.keys.first(where: { $0.caseInsensitiveCompare(key) == .orderedSame }) {
                    mergeResult.dictionary[foundKey] = nil
                }
            }
            mergeResult.dictionary[key] = value
        }
        return mergeResult
    }
    
    private static func getClassName(value: Any) -> String {
        return "\(type(of: value))"
    }
    
    private static func checkType(value: Any?) -> TypeResult {
        var typeResult = TypeResult(isOptional: false, unwrappedType: Any.Type.self)
        
//        print(getClassName(value: value))
        if let value = value {
            // Optional type unwrapping
            if let optional = value as? OptionalProtocol {
//                print(optional.wrappedType())
                typeResult.unwrappedType = optional.wrappedType()
                typeResult.isOptional = true
            }
            // Non-optional type
            else {
                typeResult.unwrappedType = type(of: value)
            }
        }
        // No valid value found; must be optional since value is nil
        else {
            if let optional = value as? OptionalProtocol {
//                print(optional.wrappedType())
                typeResult.unwrappedType = optional.wrappedType()
                typeResult.isOptional = true
            }
        }
        return typeResult
    }
    
    private static func checkTypes(valueA: Any?, valueB: Any?) -> (isValueTypeSame: Bool, typeResultA: TypeResult, typeResultB: TypeResult) {
        // Reliance on the string conversion of a given type?
        // for some reason passing the value to a function re-anonymizes the type
        var typeResultA = TypeResult(isOptional: false, unwrappedType: Any.Type.self)
        var typeResultB = TypeResult(isOptional: false, unwrappedType: Any.Type.self)
        
        // Value A
//        print(getClassName(value: valueA))
        if let valueA = valueA {
            // Optional type unwrapping
            if let optional = valueA as? OptionalProtocol {
//                print(optional.wrappedType())
                typeResultA.unwrappedType = optional.wrappedType()
                typeResultA.isOptional = true
            }
            // Non-optional type
            else {
                typeResultA.unwrappedType = type(of: valueA)
            }
        }
        // No valid value found; must be optional since value is nil
        else {
            if let optional = valueA as? OptionalProtocol {
//                print(optional.wrappedType())
                typeResultA.unwrappedType = optional.wrappedType()
                typeResultA.isOptional = true
            }
        }
        
        
        // Value B
//        print(getClassName(value: valueB))
        if let valueB = valueB {
            if let optional = valueB as? OptionalProtocol {
//                print(optional.wrappedType())
                typeResultB.unwrappedType = optional.wrappedType()
                typeResultB.isOptional = true
            }
            else {
                typeResultB.unwrappedType = type(of: valueB)
            }
        }
        else {
            if let optional = valueB as? OptionalProtocol {
//                print(optional.wrappedType())
                typeResultB.unwrappedType = optional.wrappedType()
                typeResultB.isOptional = true
            }
        }
        
//        print("typeA: \(typeResultA)")
//        print("typeB: \(typeResultB)")
//        print("typeA == typeB: \(typeResultA == typeResultB)")
        // what were the keys, what value were they tied to
        // keys value types mismatched or optional vs nonoptional
        return (isValueTypeSame: typeResultA == typeResultB, typeResultA: typeResultA, typeResultB: typeResultB)
    }
    
    private func handleCaptureContextData(event: Event) {
        // add to existing list
        EdgeBridge.contextDataStore.append(event)
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
            handleCaptureContextData(event: xdmEvent)
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

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

/// Type metadata container that keeps track of type information
/// Supports equality operations, which checks for both `unwrappedType` and `isOptional` equivalence
private struct TypeResult: CustomStringConvertible, Equatable {
    static func == (lhs: TypeResult, rhs: TypeResult) -> Bool {
        if lhs.unwrappedType == rhs.unwrappedType && lhs.isOptional == rhs.isOptional {
            return true
        } else {
            return false
        }
    }
    /// Specifies if value type is Optional or not
    var isOptional: Bool
    /// The concrete type extracted from the value (can be compared with other TypeResult's `unwrappedType`)
    var unwrappedType: Any.Type

    public var description: String { return "\(isOptional ? "Optional " : "")\(unwrappedType)" }
}

/// Value type metadata container which keeps track of type and merge metadata
private struct KeySet {
    /// The original `Event` which owns this data
    var eventID: UUID
    /// The unmodified key value which was paired with this value (key values may be modified when using case insensitive merge)
    var originalKeyValue: String
    /// The TypeResult extracted for the value
    var typeResult: TypeResult
    /// The hierarchy of keys taken to reach this key value pair within the JSON (helps trace nested JSON objects)
    var keypath: [String]
}

/// The primary data store for event data merge operations. Keeps track of actual `Event` data body merge result along with
/// metadata from merge process and merge settings.
/// Initialized with an `Event` which will become the base of the overall merge
private struct MergeResult {
    /// The merge setting for whether or not key comparisons should be performed using case sensitivity or not
    let isCaseSensitive: Bool
    /// The array of `Event` IDs appended in merge order that were used to arrive at the final merge result
    var ids: [UUID]
    /// The result of the merge process for the given `Event`s
    var dictionary: [String: Any]
    /// The flat mapping of keys to the KeySet value type metadata
    /// Keys are set in case sensitive or insensitive format depending on merge setting (original key value can be obtained from KeySet struct)
    var keySet: [String: [KeySet]]

    /// Initializes the MergeResult using an `Event`
    init(event: Event, isCaseSensitive: Bool, keySetResult: [String: [KeySet]]) {
        self.isCaseSensitive = isCaseSensitive
        self.ids = [event.id]
        self.dictionary = event.data ?? [:]
        self.keySet = keySetResult
    }
}

class ContextDataCapturer {

    var isActive: Bool = false
    var contextDataStore: [Event] = []

    /// Starts a debug context data capture session which tracks all context data handed by the Edge Bridge extension.
    /// Once the session is stopped, a report is generated containing a merged view of the captured context data keys
    /// and values. This report can then be uploaded to Data Prep for Data Collection to map the context data to XDM.
    ///
    /// Note, this API is intended for use during debugging and should not be used in a production environment. The
    /// SDK log level must be configured to `LogLevel.debug` or `LogLevel.trace` for the report to be printed.
    public func startCapture() {
        isActive = true
    }

    /// Adds the Event to the capture list, given a context data capturing session is active; use `startCapture()`to
    /// start a capture session
    public func addEvent(_ event: Event) {
        if isActive {
            contextDataStore.append(event)
        }
    }

    /// Stops a debug context data capture session and prints a report of the captured context data keys and values during
    /// the session to the device logs. The report can then be uploaded to Data Prep for Data Collection to map the context
    /// data to XDM.
    ///
    /// Note, this API is intended for use during debugging and should not be used in a production environment. The SDK log
    /// level must be configured to `LogLevel.debug` or `LogLevel.trace` for the report to be printed.
    ///
    /// - Parameters:
    ///     - withMerge: Controls if merge logic is applied to captured `Event`s
    ///     - isMergeCaseSensitive: Controls if merge logic for matching keys uses case sensitive compare or not
    public func stopCapture(withMerge: Bool, isMergeCaseSensitive: Bool) {
        if !isActive {
            Log.debug(label: EdgeBridgeConstants.LOG_TAG, "Context data capture is already disabled. Ignoring received stop capture event.")
            return
        }
        isActive = false
        outputCapturedContextData(withMerge: withMerge, isMergeCaseSensitive: isMergeCaseSensitive)
        contextDataStore.removeAll()
    }

    /// Outputs context data that has been captured up to the point the method is called; does not affect capture status or collected data.
    ///
    /// - Parameters:
    ///     - withMerge: Controls if merge logic is applied to captured `Event`s
    ///     - isMergeCaseSensitive: Controls if merge logic for matching keys uses case sensitive compare or not
    private func outputCapturedContextData(withMerge: Bool, isMergeCaseSensitive: Bool) {
        var mergeReport = ""

        func addToMergeReport(text: String) {
            mergeReport += text + "\n"
        }
        if withMerge {
            guard let firstEvent = contextDataStore.first else {
                Log.debug(label: EdgeBridgeConstants.LOG_TAG, "No events to merge.")
                return
            }
            // Initialize merge result using first valid event
            var mergeResult = MergeResult(event: firstEvent, isCaseSensitive: isMergeCaseSensitive, keySetResult: extractKeySet(event: firstEvent, isCaseSensitive: isMergeCaseSensitive))
            // Start merging next events into result
            if contextDataStore.count > 1 {
                for i in 1..<contextDataStore.count {
                    mergeResult = mergeEvents(mergeResult: mergeResult, eventToMerge: contextDataStore[i])
                }
            }
            addToMergeReport(text: "============== Merge Result =================")
            addToMergeReport(text: "-------------- Value type/key merge conflicts --------------")
            for (key, value) in mergeResult.keySet {
                // For each key, group by keypath to find actual key conflicts
                var keysets = value

                while !keysets.isEmpty {
                    guard let keypath = keysets.first?.keypath else { break }
                    let matchingKeysets = keysets.filter({ $0.keypath == keypath })
                    keysets.removeAll(where: { $0.keypath == keypath })
                    if matchingKeysets.count <= 1 { continue }
                    // Check for conflicts in:
                    // 1. Original key value
                    if !matchingKeysets.allSatisfy({ $0.originalKeyValue == matchingKeysets.first!.originalKeyValue }) {
                        addToMergeReport(text: "Key string mismatch (keypath: \(keypath)): \(matchingKeysets.map({($0.eventID, $0.originalKeyValue)}))")
                    }
                    // 2. Types and Optional status
                    if !matchingKeysets.allSatisfy({ $0.typeResult == matchingKeysets.first!.typeResult }) {
                        addToMergeReport(text: "Value type mismatch (keypath: \(keypath)): \(matchingKeysets.map({($0.eventID, $0.originalKeyValue, $0.typeResult)}))")
                    }
                }
            }
            addToMergeReport(text: "------------- Merge Dictionary ----------------")
            addToMergeReport(text: getPrettyPrintJson(json: mergeResult.dictionary))
        }
        addToMergeReport(text: "Number of events captured: \(contextDataStore.count)")
        addToMergeReport(text: "Event IDs in merged order: \(contextDataStore.map({ $0.id }))")
        for event in contextDataStore {

            addToMergeReport(text: "Event: \(event.id) - data:")
            addToMergeReport(text: getPrettyPrintJson(json: event.data))
        }
        Log.debug(label: EdgeBridgeConstants.LOG_TAG, mergeReport)
    }

    /// Pretty prints JSON objects, checking for any `nil` values
    /// - Parameters:
    ///     - json: The valid JSON object to print
    private func getPrettyPrintJson(json: Any?) -> String {
        guard let json = json else {
            return "Nil object. Invalid JSON data format; unable to print data."
        }

        if let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
            return String(decoding: jsonData, as: UTF8.self)
        } else {
            return "Invalid JSON data format; unable to print data."
        }
    }

    /// Extracts value types from Event dictionary, keeping track of the hierarchy of keys in the case of nested dictionaries
    /// the key in the returned dictionary is based on what matching system will be used; that is, when using case insensitive compare,
    /// a `.lowercase()` transform is applied. Original key value is stored in keyset
    private func extractKeySet(event: Event, isCaseSensitive: Bool) -> [String: [KeySet]] {
        return extractKeySet(dictionary: event.data ?? [:], eventID: event.id, isCaseSensitive: isCaseSensitive, keypath: [])
    }

    /// Extracts value types from dictionary, keeping track of the hierarchy of keys in the case of nested dictionaries
    /// the key in the returned dictionary is based on what matching system will be used; that is, when using case insensitive compare,
    /// a `.lowercase()` transform is applied. Original key value is stored in keyset
    private func extractKeySet(dictionary: [String: Any], eventID: UUID, isCaseSensitive: Bool, keypath: [String]) -> [String: [KeySet]] {
        var result: [String: [KeySet]] = [:]

        for (key, value) in dictionary {
            // Determine the search key to use based on case sensitive setting
            // The logic for value type collision here and the dictionary merge being consistent
            // depends on the `.lowercased()` and `.caseInsensitiveCompare()` being equivalent operations
            let finalKey = isCaseSensitive ? key : key.lowercased()
            let typeResult = checkType(value: value)
            let keySet = KeySet(eventID: eventID, originalKeyValue: key, typeResult: typeResult, keypath: keypath)
            if let record = result[finalKey] {
                result[finalKey]?.append(keySet)
            } else {
                result[finalKey] = [keySet]
            }
            if value is [String: Any] {
                guard let childDictionary = value as? [String: Any] else { continue }
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

    /// Merges the data body from an event into a `MergeResult`
    private func mergeEvents(mergeResult: MergeResult, eventToMerge: Event) -> MergeResult {
        var mergeResult = mergeResult
        mergeResult.ids.append(eventToMerge.id)

        let dictionaryToMerge = eventToMerge.data ?? [:]

        // Extract type information
        let keySetToMerge = extractKeySet(dictionary: dictionaryToMerge, eventID: eventToMerge.id, isCaseSensitive: mergeResult.isCaseSensitive, keypath: [])
        mergeResult.keySet.merge(keySetToMerge, uniquingKeysWith: { lhs, rhs in
            var result = lhs
            result.append(contentsOf: rhs)
            return result
        })

        // Merge event data into result
        mergeResult.dictionary = deepMerge(mergeResult.dictionary, dictionaryToMerge, isCaseSensitive: mergeResult.isCaseSensitive)

        return mergeResult
    }

    /// Merges two dictionaries using case insensitive compare
    /// - Parameters:
    ///     - d1: The base dictionary that new records are merged into; that is, matching keys on this side of the merge are replaced
    ///     - d2: The incoming dictionary that records are sourced from; that is, matching keys on this side of the merge are used
    ///     - isCaseSensitive: Controls whether or not a case sensitive compare is used in the key matching logic
    /// - Returns: Dictionary with deep merge applied, using `isCaseSensitive` setting uniformly across merge process
    private func deepMerge(_ d1: [String: Any], _ d2: [String: Any], isCaseSensitive: Bool) -> [String: Any] {
        var result = d1
        for (k2, v2) in d2 {
            var searchKey = k2
            // Removes all keys in the result dictionary that match the case insensitive pattern,
            // except for the last one when ordered alphabetically
            if !isCaseSensitive {
                // This should be a very rare case, only simple replacement applied, no deep merge
                var foundPairs = result.filter({ $0.key.caseInsensitiveCompare(k2) == .orderedSame }).map({ (key: $0.key, value: $0.value) })
                guard foundPairs.count > 0 else {
                    result[k2] = v2
                    continue
                }
                foundPairs = foundPairs.sorted(by: { $0.key < $1.key })
                let lastPair = foundPairs.removeLast()
                for key in foundPairs.map({ $0.key }) {
                    result.removeValue(forKey: key)
                }

                searchKey = lastPair.key
            }
            // Check the value for the key in both dictionaries
            if let v1 = result[searchKey] as? [String: Any], let v2 = v2 as? [String: Any] {
                result[k2] = deepMerge(v1, v2, isCaseSensitive: isCaseSensitive)
            } else {
                result[k2] = v2
            }
            // Remove the original case insensitive search key from the result dictionary, only if it does not match
            // the incoming key (to avoid duplicates in the result)
            if !isCaseSensitive && searchKey.compare(k2) != .orderedSame {
                result[searchKey] = nil
            }
        }
        return result
    }

    /// Checks single value type, unwrapping anonymous `Any` type; only unwraps one level down
    /// - Parameters:
    ///     - value: The value whose type is to be determined
    /// - Returns: TypeResult - result that holds unwrapped type and if type is optional or not
    private func checkType(value: Any?) -> TypeResult {
        var typeResult = TypeResult(isOptional: false, unwrappedType: Any.Type.self)

        if let value = value {
            // Optional type unwrapping
            if let optional = value as? OptionalProtocol {
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
                typeResult.unwrappedType = optional.wrappedType()
                typeResult.isOptional = true
            }
        }
        return typeResult
    }
}

private protocol OptionalProtocol {
    func wrappedType() -> Any.Type
}

extension Optional: OptionalProtocol {
    func wrappedType() -> Any.Type {
        return Wrapped.self
    }
}

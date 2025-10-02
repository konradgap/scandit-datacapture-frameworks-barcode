/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import ScanditFrameworksCore
import ScanditCaptureCore

struct BarcodeFindViewCreationData {
    let modeJson: String
    let viewJson: String
    let itemsToFind: BarcodeFindItemsData?
    let startSearching: Bool
    let hasBarcodeTransformer: Bool
    let isModeEnabled: Bool
    let hasModeListeners: Bool
    let hasViewListener: Bool
    let viewId: Int

    private static let modeKey = "BarcodeFind"
    private static let viewKey = "View"
    private static let itemsToFindKey = "itemsToFind"
    private static let startSearchingKey = "startSearching"
    private static let hasBarcodeTransformerKey = "hasBarcodeTransformer"
    private static let modeEnabledKey = "enabled"
    private static let hasModeListenersKey = "hasListeners"
    private static let hasViewListenerKey = "hasListener"
    private static let viewIdKey = "viewId"

    static func fromJson(viewJson: String) throws -> BarcodeFindViewCreationData {
        let json = JSONValue(string: viewJson)

        let hasAllRequiredFields = json.containsKey(modeKey) && json.containsKey(viewKey)

        if !hasAllRequiredFields {
            throw ScanditFrameworksCoreError.deserializationError(
                error: NSError(
                    domain: "BarcodeFindViewCreationData",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Unable to create a BarcodeFindView. " +
                        "The given json doesn't contain all the required fields. " +
                        "Required fields = [\(modeKey), \(viewKey)]"
                    ]
                ),
                json: viewJson
            )
        }

        // Get JSON objects directly, defaulting to empty objects
        let viewJsonObject = json.object(forKey: viewKey)
        let modeJsonObject = json.object(forKey: modeKey)

        var itemsToFind: BarcodeFindItemsData? = nil
        if modeJsonObject.containsKey(itemsToFindKey) {
            itemsToFind = BarcodeFindItemsData(jsonString: modeJsonObject.string(forKey: itemsToFindKey))
        }

        return BarcodeFindViewCreationData(
            modeJson: modeJsonObject.jsonString(),
            viewJson: viewJsonObject.jsonString(),
            itemsToFind: itemsToFind,
            startSearching: viewJsonObject.bool(forKey: startSearchingKey, default: false),
            hasBarcodeTransformer: modeJsonObject.bool(forKey: hasBarcodeTransformerKey, default: false),
            isModeEnabled: modeJsonObject.bool(forKey: modeEnabledKey, default: false),
            hasModeListeners: modeJsonObject.bool(forKey: hasModeListenersKey, default: false),
            hasViewListener: viewJsonObject.bool(forKey: hasViewListenerKey, default: false),
            viewId: viewJsonObject.integer(forKey: viewIdKey)
        )
    }

    static func fromModeJsonOnly(modeJson: String) -> BarcodeFindViewCreationData {
        let json = JSONValue(string: modeJson)

        var itemsToFind: BarcodeFindItemsData? = nil
        if json.containsKey(itemsToFindKey) {
            itemsToFind = BarcodeFindItemsData(jsonString: json.string(forKey: itemsToFindKey))
        }

        return BarcodeFindViewCreationData(
            modeJson: modeJson,
            viewJson: "{}",
            itemsToFind: itemsToFind,
            startSearching: false,
            hasBarcodeTransformer: json.bool(forKey: hasBarcodeTransformerKey, default: false),
            isModeEnabled: json.bool(forKey: modeEnabledKey, default: false),
            hasModeListeners: json.bool(forKey: hasModeListenersKey, default: false),
            hasViewListener: false,
            viewId: -1
        )
    }

    static func fromViewJsonOnly(viewJson: String) -> BarcodeFindViewCreationData {
        let json = JSONValue(string: viewJson)

        var itemsToFind: BarcodeFindItemsData? = nil
        if json.containsKey(itemsToFindKey) {
            itemsToFind = BarcodeFindItemsData(jsonString: json.string(forKey: itemsToFindKey))
        }

        return BarcodeFindViewCreationData(
            modeJson: "{}",
            viewJson: viewJson,
            itemsToFind: itemsToFind,
            startSearching: json.bool(forKey: startSearchingKey, default: false),
            hasBarcodeTransformer: false,
            isModeEnabled: false,
            hasModeListeners: false,
            hasViewListener: json.bool(forKey: hasViewListenerKey, default: false),
            viewId: json.integer(forKey: viewIdKey)
        )
    }
}

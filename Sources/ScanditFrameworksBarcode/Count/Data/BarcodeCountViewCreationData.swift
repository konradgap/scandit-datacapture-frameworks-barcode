/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import Foundation

public class BarcodeCountViewCreationData {
    let modeJson: String
    let viewJson: String
    let hasModeListener: Bool
    let hasViewListener: Bool
    let hasUIListener: Bool
    let viewId: Int
    let isModeEnabled: Bool
    let hasStatusProvider: Bool

    private enum Keys {
        static let modeKey = "BarcodeCount"
        static let viewKey = "View"
        static let modeEnabledKey = "isEnabled"
        static let hasUIListenerKey = "hasUiListener"
        static let hasViewListenerKey = "hasListeners"
        static let viewIdKey = "viewId"
        static let hasModeListenerKey = "hasListeners"
        static let hasStatusProviderKey = "hasStatusProvider"
    }

    init(modeJson: String,
         viewJson: String,
         hasModeListener: Bool,
         hasViewListener: Bool,
         hasUIListener: Bool,
         viewId: Int,
         isModeEnabled: Bool,
         hasStatusProvider: Bool) {
        self.modeJson = modeJson
        self.viewJson = viewJson
        self.hasModeListener = hasModeListener
        self.hasViewListener = hasViewListener
        self.hasUIListener = hasUIListener
        self.viewId = viewId
        self.isModeEnabled = isModeEnabled
        self.hasStatusProvider = hasStatusProvider
    }

    static func fromJson(_ viewJson: String) throws -> BarcodeCountViewCreationData {
        guard let jsonData = viewJson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return getDefaultCreationParams()
        }

        
        let hasAllRequiredFields = json[Keys.modeKey] != nil && json[Keys.viewKey] != nil
        if !hasAllRequiredFields {
            throw NSError(domain: "BarcodeCountViewCreationData", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unable to create a BarcodeCountView. The given json doesn't contain all the required fields. Required fields = [\(Keys.modeKey), \(Keys.viewKey)]"])
        }

        let viewJsonObject = json[Keys.viewKey] as? [String: Any] ?? [:]
        let modeJsonObject = json[Keys.modeKey] as? [String: Any] ?? [:]

        let modeJsonString = convertToJsonString(modeJsonObject) ?? "{}"
        let viewJsonString = convertToJsonString(viewJsonObject) ?? "{}"

        return BarcodeCountViewCreationData(
            modeJson: modeJsonString,
            viewJson: viewJsonString,
            hasModeListener: (modeJsonObject[Keys.hasModeListenerKey] as? Bool) ?? false,
            hasViewListener: (viewJsonObject[Keys.hasViewListenerKey] as? Bool) ?? false,
            hasUIListener: (viewJsonObject[Keys.hasUIListenerKey] as? Bool) ?? false,
            viewId: (viewJsonObject[Keys.viewIdKey] as? Int) ?? -1,
            isModeEnabled: (modeJsonObject[Keys.modeEnabledKey] as? Bool) ?? false,
            hasStatusProvider: (viewJsonObject[Keys.hasStatusProviderKey] as? Bool) ?? false
        )
    }

    static func fromViewJsonOnly(_ viewJson: String) throws -> BarcodeCountViewCreationData {
        guard let data = viewJson.data(using: .utf8),
              let viewJsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return getDefaultCreationParams()
        }
        return BarcodeCountViewCreationData(
            modeJson: "{}",
            viewJson: viewJson,
            hasModeListener: false,
            hasViewListener: (viewJsonObject[Keys.hasViewListenerKey] as? Bool) ?? false,
            hasUIListener: (viewJsonObject[Keys.hasUIListenerKey] as? Bool) ?? false,
            viewId: (viewJsonObject[Keys.viewIdKey] as? Int) ?? -1,
            isModeEnabled: false,
            hasStatusProvider: (viewJsonObject[Keys.hasStatusProviderKey] as? Bool) ?? false
        )
    }

    static func fromModeJsonOnly(_ modeJson: String) throws -> BarcodeCountViewCreationData {
        guard let data = modeJson.data(using: .utf8),
              let modeJsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return getDefaultCreationParams()
        }
        return BarcodeCountViewCreationData(
            modeJson: modeJson,
            viewJson: "{}",
            hasModeListener: (modeJsonObject[Keys.hasModeListenerKey] as? Bool) ?? false,
            hasViewListener: false,
            hasUIListener: false,
            viewId: -1,
            isModeEnabled: (modeJsonObject[Keys.modeEnabledKey] as? Bool) ?? false,
            hasStatusProvider: false
        )
    }
    
    private static func convertToJsonString(_ dict: [String: Any]) -> String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict) else {
            return nil
        }
        return String(data: jsonData, encoding: .utf8)
    }
    
    private static func getDefaultCreationParams() -> BarcodeCountViewCreationData {
        // Return default values if JSON parsing fails
        return BarcodeCountViewCreationData(
            modeJson: "{}",
            viewJson: "{}",
            hasModeListener: false,
            hasViewListener: false,
            hasUIListener: false,
           viewId:       0,
            isModeEnabled: false,
            hasStatusProvider: false
        )
    }
}

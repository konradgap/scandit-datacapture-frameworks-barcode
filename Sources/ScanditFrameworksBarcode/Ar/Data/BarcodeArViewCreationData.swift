/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import Foundation

public class BarcodeArViewCreationData {
    let modeJson: String
    let viewJson: String
    let hasModeListener: Bool
    let hasUIListener: Bool
    let hasHighlightProvider: Bool
    let hasAnnotationProvider: Bool
    let viewId: Int
    let isModeEnabled: Bool
    let isStarted: Bool

    private enum Keys {
        static let modeKey = "BarcodeAr"
        static let viewKey = "View"
        static let modeEnabledKey = "isEnabled"
        static let hasUIListenerKey = "hasUiListener"
        static let hasHighlightProviderKey = "hasHighlightProvider"
        static let hasAnnotationProviderKey = "hasAnnotationProvider"
        static let viewIdKey = "viewId"
        static let hasModeListenerKey = "hasModeListener"
        static let isStartedKey = "isStarted"
    }

    init(modeJson: String,
         viewJson: String,
         hasModeListener: Bool,
         hasUIListener: Bool,
         hasHighlightProvider: Bool,
         hasAnnotationProvider: Bool,
         viewId: Int,
         isModeEnabled: Bool,
         isStarted: Bool) {
        self.modeJson = modeJson
        self.viewJson = viewJson
        self.hasModeListener = hasModeListener
        self.hasUIListener = hasUIListener
        self.hasHighlightProvider = hasHighlightProvider
        self.hasAnnotationProvider = hasAnnotationProvider
        self.viewId = viewId
        self.isModeEnabled = isModeEnabled
        self.isStarted = isStarted
    }

    static func fromJson(_ viewJson: String) throws -> BarcodeArViewCreationData {
        guard let jsonData = viewJson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return getDefaultCreationParams()
        }

        let hasAllRequiredFields = json[Keys.modeKey] != nil && json[Keys.viewKey] != nil
        if !hasAllRequiredFields {
            throw NSError(domain: "BarcodeArViewCreationData", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unable to create a BarcodeArView. The given json doesn't contain all the required fields. Required fields = [\(Keys.modeKey), \(Keys.viewKey)]"])
        }

        let viewJsonObject = json[Keys.viewKey] as? [String: Any] ?? [:]
        let modeJsonObject = json[Keys.modeKey] as? [String: Any] ?? [:]

        let modeJsonString = convertToJsonString(modeJsonObject) ?? "{}"
        let viewJsonString = convertToJsonString(viewJsonObject) ?? "{}"

        return BarcodeArViewCreationData(
            modeJson: modeJsonString,
            viewJson: viewJsonString,
            hasModeListener: (modeJsonObject[Keys.hasModeListenerKey] as? Bool) ?? false,
            hasUIListener: (viewJsonObject[Keys.hasUIListenerKey] as? Bool) ?? false,
            hasHighlightProvider: (viewJsonObject[Keys.hasHighlightProviderKey] as? Bool) ?? false,
            hasAnnotationProvider: (viewJsonObject[Keys.hasAnnotationProviderKey] as? Bool) ?? false,
            viewId: (viewJsonObject[Keys.viewIdKey] as? Int) ?? -1,
            isModeEnabled: (modeJsonObject[Keys.modeEnabledKey] as? Bool) ?? false,
            isStarted: (viewJsonObject[Keys.isStartedKey] as? Bool) ?? false
        )
    }

    static func fromViewJsonOnly(_ viewJson: String) throws -> BarcodeArViewCreationData {
        guard let data = viewJson.data(using: .utf8),
              let viewJsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return getDefaultCreationParams()
        }
        return BarcodeArViewCreationData(
            modeJson: "{}",
            viewJson: viewJson,
            hasModeListener: false,
            hasUIListener: (viewJsonObject[Keys.hasUIListenerKey] as? Bool) ?? false,
            hasHighlightProvider: (viewJsonObject[Keys.hasHighlightProviderKey] as? Bool) ?? false,
            hasAnnotationProvider: (viewJsonObject[Keys.hasAnnotationProviderKey] as? Bool) ?? false,
            viewId: (viewJsonObject[Keys.viewIdKey] as? Int) ?? -1,
            isModeEnabled: false,
            isStarted: (viewJsonObject[Keys.isStartedKey] as? Bool) ?? false
        )
    }

    static func fromModeJsonOnly(_ modeJson: String) throws -> BarcodeArViewCreationData {
        guard let data = modeJson.data(using: .utf8),
              let modeJsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return getDefaultCreationParams()
        }
        return BarcodeArViewCreationData(
            modeJson: modeJson,
            viewJson: "{}",
            hasModeListener: (modeJsonObject[Keys.hasModeListenerKey] as? Bool) ?? false,
            hasUIListener: false,
            hasHighlightProvider: false,
            hasAnnotationProvider: false,
            viewId: -1,
            isModeEnabled: (modeJsonObject[Keys.modeEnabledKey] as? Bool) ?? false,
            isStarted: false
        )
    }

    private static func convertToJsonString(_ dict: [String: Any]) -> String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict) else {
            return nil
        }
        return String(data: jsonData, encoding: .utf8)
    }

    private static func getDefaultCreationParams() -> BarcodeArViewCreationData {
        // Return default values if JSON parsing fails
        return BarcodeArViewCreationData(
            modeJson: "{}",
            viewJson: "{}",
            hasModeListener: false,
            hasUIListener: false,
            hasHighlightProvider: false,
            hasAnnotationProvider: false,
            viewId: 0,
            isModeEnabled: false,
            isStarted: false
        )
    }
}

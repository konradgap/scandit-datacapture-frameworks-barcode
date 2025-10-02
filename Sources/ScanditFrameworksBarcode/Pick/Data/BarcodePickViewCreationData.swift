/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import Foundation

public class BarcodePickViewCreationData {
    let modeJson: String
    let viewJson: String
    let viewSettings: String
    let productProviderJson: String
    let hasListeners: Bool
    let hasScanningListeners: Bool
    let hasActionListeners: Bool
    let hasViewListeners: Bool
    let hasViewUiListener: Bool
    let viewId: Int
    let isStarted: Bool
    let highlightType: HighlightType
    let hasAsyncProvider: Bool

    public enum HighlightType {
        case none
        case dot
        case dotWithIcons
        case rectangular
        case rectangularWithIcons
        case customView
    }

    private enum Keys {
        static let modeKey = "BarcodePick"
        static let viewKey = "View"
        static let viewSettingsKey = "viewSettings"
        static let providerKey = "ProductProvider"
        static let viewIdKey = "viewId"
        static let hasListenersKey = "hasListeners"
        static let hasScanningListenersKey = "hasScanningListeners"
        static let hasActionListenersKey = "hasActionListeners"
        static let hasViewListenersKey = "hasViewListeners"
        static let hasViewUiListenerKey = "hasViewUiListener"
        static let isStartedKey = "isStarted"
        static let highlightStyleKey = "highlightStyle"
        static let highlightStyleTypeKey = "type"
        static let highlightStyleHasProviderKey = "hasAsyncProvider"
    }

    init(modeJson: String,
         viewJson: String,
         viewSettings: String,
         productProviderJson: String,
         hasListeners: Bool,
         hasScanningListeners: Bool,
         hasActionListeners: Bool,
         hasViewListeners: Bool,
         hasViewUiListener: Bool,
         viewId: Int,
         isStarted: Bool,
         highlightType: HighlightType,
         hasAsyncProvider: Bool) {
        self.modeJson = modeJson
        self.viewJson = viewJson
        self.viewSettings = viewSettings
        self.productProviderJson = productProviderJson
        self.hasListeners = hasListeners
        self.hasScanningListeners = hasScanningListeners
        self.hasActionListeners = hasActionListeners
        self.hasViewListeners = hasViewListeners
        self.hasViewUiListener = hasViewUiListener
        self.viewId = viewId
        self.isStarted = isStarted
        self.highlightType = highlightType
        self.hasAsyncProvider = hasAsyncProvider
    }

    static func fromJson(_ viewJson: String) throws -> BarcodePickViewCreationData {
        guard let jsonData = viewJson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return getDefaultCreationParams()
        }

        let hasAllRequiredFields = json[Keys.modeKey] != nil && json[Keys.viewKey] != nil
        if !hasAllRequiredFields {
            throw NSError(domain: "BarcodePickViewCreationData", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unable to create a BarcodePick. The given json doesn't contain all the required fields. Required fields = [\(Keys.modeKey), \(Keys.viewKey)]"])
        }

        let viewJsonObject = json[Keys.viewKey] as? [String: Any] ?? [:]
        let modeJsonObject = json[Keys.modeKey] as? [String: Any] ?? [:]
        let viewSettingsJsonObject = viewJsonObject[Keys.viewSettingsKey] as? [String: Any] ?? [:]
        let productProviderJsonObject = modeJsonObject[Keys.providerKey] as? [String: Any] ?? [:]

        let modeJsonString = convertToJsonString(modeJsonObject) ?? "{}"
        let viewJsonString = convertToJsonString(viewJsonObject) ?? "{}"
        let viewSettingsJsonString = convertToJsonString(viewSettingsJsonObject) ?? "{}"
        let productProviderJsonString = convertToJsonString(productProviderJsonObject) ?? "{}"

        // Parse highlight style information
        let highlightStyleJsonObject = viewSettingsJsonObject[Keys.highlightStyleKey] as? [String: Any] ?? [:]
        let highlightType = parseHighlightType(from: highlightStyleJsonObject[Keys.highlightStyleTypeKey] as? String)
        let hasAsyncProvider = highlightStyleJsonObject[Keys.highlightStyleHasProviderKey] as? Bool ?? false

        return BarcodePickViewCreationData(
            modeJson: modeJsonString,
            viewJson: viewJsonString,
            viewSettings: viewSettingsJsonString,
            productProviderJson: productProviderJsonString,
            hasListeners: (modeJsonObject[Keys.hasListenersKey] as? Bool) ?? false,
            hasScanningListeners: (modeJsonObject[Keys.hasScanningListenersKey] as? Bool) ?? false,
            hasActionListeners: (viewJsonObject[Keys.hasActionListenersKey] as? Bool) ?? false,
            hasViewListeners: (viewJsonObject[Keys.hasViewListenersKey] as? Bool) ?? false,
            hasViewUiListener: (viewJsonObject[Keys.hasViewUiListenerKey] as? Bool) ?? false,
            viewId: (viewJsonObject[Keys.viewIdKey] as? Int) ?? -1,
            isStarted: (viewJsonObject[Keys.isStartedKey] as? Bool) ?? false,
            highlightType: highlightType,
            hasAsyncProvider: hasAsyncProvider
        )
    }

    static func fromViewJsonOnly(_ viewJson: String) throws -> BarcodePickViewCreationData {
        guard let data = viewJson.data(using: .utf8),
              let viewJsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let viewSettingsJsonObject = viewJsonObject[Keys.viewSettingsKey] as? [String: Any],
              let viewSettingsJsonString = convertToJsonString(viewSettingsJsonObject) else {
            return getDefaultCreationParams()
        }

        // Parse highlight style information
        let highlightStyleJsonObject = viewSettingsJsonObject[Keys.highlightStyleKey] as? [String: Any] ?? [:]
        let highlightType = parseHighlightType(from: highlightStyleJsonObject[Keys.highlightStyleTypeKey] as? String)
        let hasAsyncProvider = highlightStyleJsonObject[Keys.highlightStyleHasProviderKey] as? Bool ?? false

        return BarcodePickViewCreationData(
            modeJson: "{}",
            viewJson: viewJson,
            viewSettings: viewSettingsJsonString,
            productProviderJson: "{}",
            hasListeners: false,
            hasScanningListeners: (viewJsonObject[Keys.hasScanningListenersKey] as? Bool) ?? false,
            hasActionListeners: (viewJsonObject[Keys.hasActionListenersKey] as? Bool) ?? false,
            hasViewListeners: (viewJsonObject[Keys.hasViewListenersKey] as? Bool) ?? false,
            hasViewUiListener: (viewJsonObject[Keys.hasViewUiListenerKey] as? Bool) ?? false,
            viewId: (viewJsonObject[Keys.viewIdKey] as? Int) ?? -1,
            isStarted: (viewJsonObject[Keys.isStartedKey] as? Bool) ?? false,
            highlightType: highlightType,
            hasAsyncProvider: hasAsyncProvider
        )
    }

    static func fromModeJsonOnly(_ modeJson: String) throws -> BarcodePickViewCreationData {
        guard let data = modeJson.data(using: .utf8),
              let modeJsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let productProviderJsonObject = modeJsonObject[Keys.providerKey] as? [String: Any],
              let productProviderJsonString = convertToJsonString(productProviderJsonObject)
        else {
            return getDefaultCreationParams()
        }
        return BarcodePickViewCreationData(
            modeJson: modeJson,
            viewJson: "{}",
            viewSettings: "{}",
            productProviderJson: productProviderJsonString,
            hasListeners: false,
            hasScanningListeners: (modeJsonObject[Keys.hasListenersKey] as? Bool) ?? false,
            hasActionListeners: false,
            hasViewListeners: false,
            hasViewUiListener: false,
            viewId: -1,
            isStarted: false,
            highlightType: .none,
            hasAsyncProvider: false
        )
    }

    private static func parseHighlightType(from typeString: String?) -> HighlightType {
        guard let typeString = typeString else { return .none }

        switch typeString {
        case "dot":
            return .dot
        case "dotWithIcons":
            return .dotWithIcons
        case "rectangular":
            return .rectangular
        case "rectangularWithIcons":
            return .rectangularWithIcons
        case "customView":
            return .customView
        default:
            return .none
        }
    }

    private static func convertToJsonString(_ dict: [String: Any]) -> String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict) else {
            return nil
        }
        return String(data: jsonData, encoding: .utf8)
    }

    private static func getDefaultCreationParams() -> BarcodePickViewCreationData {
        return BarcodePickViewCreationData(
            modeJson: "{}",
            viewJson: "{}",
            viewSettings: "{}",
            productProviderJson: "{}",
            hasListeners: false,
            hasScanningListeners: false,
            hasActionListeners: false,
            hasViewListeners: false,
            hasViewUiListener: false,
            viewId: -1,
            isStarted: false,
            highlightType: .none,
            hasAsyncProvider: false
        )
    }
}

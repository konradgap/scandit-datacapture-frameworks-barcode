/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import Foundation

public class SparkScanViewCreationData {
    let modeJson: String
    let viewJson: String
    let hasModeListener: Bool
    let hasFeedbackDelegate: Bool
    let hasUIListener: Bool
    let shouldShowOnTopAlways: Bool
    let viewId: Int

    private init(
        modeJson: String,
        viewJson: String,
        hasModeListener: Bool,
        hasFeedbackDelegate: Bool,
        hasUIListener: Bool,
        shouldShowOnTopAlways: Bool,
        viewId: Int
    ) {
        self.modeJson = modeJson
        self.viewJson = viewJson
        self.hasModeListener = hasModeListener
        self.hasFeedbackDelegate = hasFeedbackDelegate
        self.hasUIListener = hasUIListener
        self.shouldShowOnTopAlways = shouldShowOnTopAlways
        self.viewId = viewId
    }

    static func fromJson(_ jsonString: String) -> SparkScanViewCreationData {
        guard let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            // Return default values if JSON parsing fails
            return SparkScanViewCreationData(
                modeJson: "{}",
                viewJson: "{}",
                hasModeListener: false,
                hasFeedbackDelegate: false,
                hasUIListener: false,
                shouldShowOnTopAlways: false,
                viewId: 0
            )
        }

        // Get JSON objects directly, defaulting to empty dictionaries
        let viewJsonObject = json[Constants.VIEW_KEY] as? [String: Any] ?? [:]
        let modeJsonObject = json[Constants.MODE_KEY] as? [String: Any] ?? [:]

        // Convert dictionaries back to JSON strings
        let modeJsonString = convertToJsonString(modeJsonObject) ?? "{}"
        let viewJsonString = convertToJsonString(viewJsonObject) ?? "{}"

        let hasViewUIListener = viewJsonObject[Constants.HAS_UI_LISTENER_KEY] as? Bool ?? false

        return SparkScanViewCreationData(
            modeJson: modeJsonString,
            viewJson: viewJsonString,
            hasModeListener: modeJsonObject[Constants.HAS_MODE_LISTENER_KEY] as? Bool ?? false,
            hasFeedbackDelegate: viewJsonObject[Constants.HAS_FEEDBACK_DELEGATE_KEY] as? Bool ?? false,
            hasUIListener: hasViewUIListener,
            shouldShowOnTopAlways: viewJsonObject[Constants.HAS_SHOULD_SHOW_VIEW_ON_TOP] as? Bool ?? false,
            viewId: viewJsonObject[Constants.VIEW_ID_KEY] as? Int ?? 0
        )
    }

    private static func convertToJsonString(_ dict: [String: Any]) -> String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict) else {
            return nil
        }
        return String(data: jsonData, encoding: .utf8)
    }

    private struct Constants {
        static let MODE_KEY = "SparkScan"
        static let VIEW_KEY = "SparkScanView"
        static let HAS_FEEDBACK_DELEGATE_KEY = "hasFeedbackDelegate"
        static let HAS_UI_LISTENER_KEY = "hasUiListener"
        static let VIEW_ID_KEY = "viewId"
        static let HAS_MODE_LISTENER_KEY = "hasListeners"
        static let HAS_SHOULD_SHOW_VIEW_ON_TOP = "shouldShowOnTopAlways"
    }
}

/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import ScanditFrameworksCore
import ScanditCaptureCore

public struct BarcodeCaptureModeCreationData {
    public let modeJson: String
    public let modeId: Int
    public let parentId: Int?
    public let hasListener: Bool
    public let isEnabled: Bool
    public let modeType: String

    private static let modeEnabledKey = "enabled"
    private static let hasListenersKey = "hasListeners"
    private static let modeIdKey = "modeId"
    private static let parentIdKey = "parentId"
    private static let typeKey = "type"

    public init(
        modeJson: String,
        modeId: Int,
        parentId: Int?,
        hasListener: Bool,
        isEnabled: Bool,
        modeType: String
    ) {
        self.modeJson = modeJson
        self.modeId = modeId
        self.parentId = parentId
        self.hasListener = hasListener
        self.isEnabled = isEnabled
        self.modeType = modeType
    }

    public static func fromJson(_ modeJson: String) throws -> BarcodeCaptureModeCreationData {
        let json = JSONValue(string: modeJson)

        let modeType = json.string(forKey: typeKey, default: "")
        if (modeType != "barcodeCapture") {
            return BarcodeCaptureModeCreationData(
                modeJson: modeJson,
                modeId: -1,
                parentId: nil,
                hasListener: false,
                isEnabled: false,
                modeType: modeType
            )
        }
        let hasListener = json.bool(forKey: hasListenersKey, default: false)
        let isEnabled = json.bool(forKey: modeEnabledKey, default: false)
        let modeId = json.integer(forKey: modeIdKey, default: -1)
        let parentId = json.optionalInt(forKey: parentIdKey)

        if modeId == -1 {
            throw ScanditFrameworksCoreError.nilArgument
        }

        return BarcodeCaptureModeCreationData(
            modeJson: modeJson,
            modeId: modeId,
            parentId: parentId,
            hasListener: hasListener,
            isEnabled: isEnabled,
            modeType: modeType
        )
    }
}

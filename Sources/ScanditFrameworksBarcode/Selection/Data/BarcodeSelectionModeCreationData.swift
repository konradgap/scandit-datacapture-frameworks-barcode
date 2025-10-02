/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import ScanditFrameworksCore
import ScanditBarcodeCapture

public struct BarcodeSelectionModeCreationData {
    let modeJson: String
    let modeId: Int
    let hasListener: Bool
    let isEnabled: Bool
    let modeType: String
    let parentId: Int

    private init(
        modeJson: String,
        modeId: Int,
        hasListener: Bool,
        isEnabled: Bool,
        modeType: String,
        parentId: Int
    ) {
        self.modeJson = modeJson
        self.modeId = modeId
        self.hasListener = hasListener
        self.isEnabled = isEnabled
        self.modeType = modeType
        self.parentId = parentId
    }

    static func fromJson(_ modeJson: String) -> BarcodeSelectionModeCreationData {
        let json = JSONValue(string: modeJson)

        let modeType = json.string(forKey: "type", default: "")

        if modeType != "barcodeSelection" {
            return BarcodeSelectionModeCreationData(
                modeJson: modeJson,
                modeId: -1,
                hasListener: false,
                isEnabled: false,
                modeType: modeType,
                parentId: -1
            )
        }

        let hasListener = json.bool(forKey: "hasListeners", default: false)
        let isEnabled = json.bool(forKey: "enabled", default: false)
        let modeId = json.integer(forKey: "modeId", default: -1)
        let parentId = json.integer(forKey: "parentId", default: -1)

        precondition(modeId != -1, "modeId must not be -1")

        return BarcodeSelectionModeCreationData(
            modeJson: modeJson,
            modeId: modeId,
            hasListener: hasListener,
            isEnabled: isEnabled,
            modeType: modeType,
            parentId: parentId
        )
    }
}

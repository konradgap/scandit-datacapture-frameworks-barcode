/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import ScanditFrameworksCore
import ScanditCaptureCore

public struct BarcodeBatchOverlayCreationData {
    public let isBasic: Bool
    public let isAdvanced: Bool
    public let overlayJsonString: String
    public let hasListeners: Bool
    public let modeId: Int

    private static let advancedOverlayType = "barcodeTrackingAdvanced"
    private static let basicOverlayType = "barcodeTrackingBasic"
    private static let typeKey = "type"
    private static let hasListenerKey = "hasListener"
    private static let modeIdKey = "modeId"

    public init(
        isBasic: Bool,
        isAdvanced: Bool,
        overlayJsonString: String,
        hasListeners: Bool,
        modeId: Int
    ) {
        self.isBasic = isBasic
        self.isAdvanced = isAdvanced
        self.overlayJsonString = overlayJsonString
        self.hasListeners = hasListeners
        self.modeId = modeId
    }

    public static func fromJson(_ overlayJsonString: String) -> BarcodeBatchOverlayCreationData {
        let overlayJson = JSONValue(string: overlayJsonString)

        let overlayType = overlayJson.string(forKey: typeKey, default: "")
        let hasListeners = overlayJson.bool(forKey: hasListenerKey, default: false)
        let modeId = overlayJson.integer(forKey: modeIdKey, default: -1)

        return BarcodeBatchOverlayCreationData(
            isBasic: overlayType == basicOverlayType,
            isAdvanced: overlayType == advancedOverlayType,
            overlayJsonString: overlayJsonString,
            hasListeners: hasListeners,
            modeId: modeId
        )
    }
}

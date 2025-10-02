/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import ScanditFrameworksCore
import ScanditCaptureCore

public struct BarcodeCaptureOverlayCreationData {
    public let isBasic: Bool
    public let overlayJsonString: String
    public let modeId: Int

    private static let basicOverlayType = "barcodeCapture"
    private static let typeKey = "type"
    private static let modeIdKey = "modeId"

    public init(
        isBasic: Bool,
        overlayJsonString: String,
        modeId: Int
    ) {
        self.isBasic = isBasic
        self.overlayJsonString = overlayJsonString
        self.modeId = modeId
    }

    public static func fromJson(_ overlayJsonString: String) -> BarcodeCaptureOverlayCreationData {
        let overlayJson = JSONValue(string: overlayJsonString)
        let overlayType = overlayJson.string(forKey: typeKey, default: "")
        let modeId = overlayJson.integer(forKey: modeIdKey, default: -1)
        
        return BarcodeCaptureOverlayCreationData(
            isBasic: overlayType == basicOverlayType,
            overlayJsonString: overlayJsonString,
            modeId: modeId
        )
    }
}

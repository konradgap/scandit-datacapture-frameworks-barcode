/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import ScanditFrameworksCore
import ScanditBarcodeCapture

public struct BarcodeSelectionOverlayCreationData {
    let isValidBasicOverlayType: Bool
    let overlayJsonString: String
    let modeId: Int
    let hasAimedBrushProvider: Bool
    let hasTrackedBrushProvider: Bool
    let textForSelectOrDoubleTapToFreezeHint: String?
    let textForTapToSelectHint: String?
    let textForDoubleTapToUnfreezeHint: String?
    let textForTapAnywhereToSelectHint: String?
    let textForAimToSelectAutoHint: String?

    private init(
        isValidBasicOverlayType: Bool,
        overlayJsonString: String,
        modeId: Int,
        hasAimedBrushProvider: Bool,
        hasTrackedBrushProvider: Bool,
        textForSelectOrDoubleTapToFreezeHint: String? = nil,
        textForTapToSelectHint: String? = nil,
        textForDoubleTapToUnfreezeHint: String? = nil,
        textForTapAnywhereToSelectHint: String? = nil,
        textForAimToSelectAutoHint: String? = nil
    ) {
        self.isValidBasicOverlayType = isValidBasicOverlayType
        self.overlayJsonString = overlayJsonString
        self.modeId = modeId
        self.hasAimedBrushProvider = hasAimedBrushProvider
        self.hasTrackedBrushProvider = hasTrackedBrushProvider
        self.textForSelectOrDoubleTapToFreezeHint = textForSelectOrDoubleTapToFreezeHint
        self.textForTapToSelectHint = textForTapToSelectHint
        self.textForDoubleTapToUnfreezeHint = textForDoubleTapToUnfreezeHint
        self.textForTapAnywhereToSelectHint = textForTapAnywhereToSelectHint
        self.textForAimToSelectAutoHint = textForAimToSelectAutoHint
    }

    static func create(overlayJson: String) -> BarcodeSelectionOverlayCreationData {
        let createOverlayJson = JSONValue(string: overlayJson)
        let type = createOverlayJson.string(forKey: "type", default: "")
        let modeId = createOverlayJson.integer(forKey: "modeId", default: -1)
        let hasAimedBrushProvider = createOverlayJson.bool(forKey: "hasAimedBrushProvider", default: false)
        let hasTrackedBrushProvider = createOverlayJson.bool(forKey: "hasTrackedBrushProvider", default: false)

        let isValidBasicOverlayType = type == "barcodeSelectionBasic"
        if !isValidBasicOverlayType {
            return BarcodeSelectionOverlayCreationData(
                isValidBasicOverlayType: false,
                overlayJsonString: "",
                modeId: modeId,
                hasAimedBrushProvider: hasAimedBrushProvider,
                hasTrackedBrushProvider: hasTrackedBrushProvider
            )
        }

        let textForSelectOrDoubleTapToFreezeHint = createOverlayJson.optionalString(forKey: "textForSelectOrDoubleTapToFreezeHint")
        let textForTapToSelectHint = createOverlayJson.optionalString(forKey: "textForTapToSelectHint")
        let textForDoubleTapToUnfreezeHint = createOverlayJson.optionalString(forKey: "textForDoubleTapToUnfreezeHint")
        let textForTapAnywhereToSelectHint = createOverlayJson.optionalString(forKey: "textForTapAnywhereToSelectHint")
        let textForAimToSelectAutoHint = createOverlayJson.optionalString(forKey: "textForAimToSelectAutoHint")

        return BarcodeSelectionOverlayCreationData(
            isValidBasicOverlayType: true,
            overlayJsonString: overlayJson,
            modeId: modeId,
            hasAimedBrushProvider: hasAimedBrushProvider,
            hasTrackedBrushProvider: hasTrackedBrushProvider,
            textForSelectOrDoubleTapToFreezeHint: textForSelectOrDoubleTapToFreezeHint,
            textForTapToSelectHint: textForTapToSelectHint,
            textForDoubleTapToUnfreezeHint: textForDoubleTapToUnfreezeHint,
            textForTapAnywhereToSelectHint: textForTapAnywhereToSelectHint,
            textForAimToSelectAutoHint: textForAimToSelectAutoHint
        )
    }
}

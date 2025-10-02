/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditFrameworksCore
import ScanditBarcodeCapture
import ScanditCaptureCore
#if SWIFT_PACKAGE
private import _ScanditFrameworksBarcodePrivate
#endif

struct FrameworksBarcodePickViewDefaults: DefaultsEncodable {
    func toEncodable() -> [String: Any?] {
        [
            "HighlightStyle": BarcodePickViewSettingsDefaults.highlightStyle.jsonString,
            "initialGuidelineText": BarcodePickViewSettingsDefaults.initialGuidelineText,
            "moveCloserGuidelineText": BarcodePickViewSettingsDefaults.moveCloserGuidelineText,
            "loadingDialogTextForPicking": BarcodePickViewSettingsDefaults.loadingDialogTextForPicking,
            "loadingDialogTextForUnpicking": BarcodePickViewSettingsDefaults.loadingDialogTextForUnpicking,
            "showLoadingDialog": BarcodePickViewSettingsDefaults.showLoadingDialog,
            "onFirstItemPickCompletedHintText": BarcodePickViewSettingsDefaults.onFirstItemPickCompletedHintText,
            "onFirstItemToPickFoundHintText": BarcodePickViewSettingsDefaults.onFirstItemToPickFoundHintText,
            "onFirstItemUnpickCompletedHintText": BarcodePickViewSettingsDefaults.onFirstItemUnpickCompletedHintText,
            "onFirstUnmarkedItemPickCompletedHintText": BarcodePickViewSettingsDefaults.onFirstUnmarkedItemPickCompletedHintText,
            "showGuidelines": BarcodePickViewSettingsDefaults.showGuidelines,
            "showHints": BarcodePickViewSettingsDefaults.showHints,
            "showFinishButton": BarcodePickViewSettingsDefaults.showFinishButton,
            "showPauseButton": BarcodePickViewSettingsDefaults.showPauseButton,
            "showZoomButton": BarcodePickViewSettingsDefaults.showZoomButton,
            "zoomButtonPosition": BarcodePickViewSettingsDefaults.zoomButtonPosition.jsonString,
            "showTorchButton": BarcodePickViewSettingsDefaults.showTorchButton,
            "torchButtonPosition": BarcodePickViewSettingsDefaults.torchButtonPosition.jsonString,
            "tapShutterToPauseGuidelineText": BarcodePickViewSettingsDefaults.tapShutterToPauseGuidelineText,
            "uiButtonsOffset": nil, // doesn't exist in iOS
            "hardwareTriggerEnabled": true, // Always enabled on iOS
            "hardwareTriggerKeyCode": nil,
            "filterHighlightSettings": BarcodeFilterHighlightSettingsDefaults.create(
                filterSettings: BarcodePickViewSettingsDefaults.filterHighlightSettings
            )
        ]
    }
}

/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2024- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture
import ScanditFrameworksCore

struct BarcodeArDefaults: DefaultsEncodable {
    let recommendedCameraSettings: CameraSettingsDefaults
    let barcodeArFeedback: BarcodeArFeedback
    let viewDefaults: DefaultsBarcodeArView

    static let shared = {
        BarcodeArDefaults(
            recommendedCameraSettings: CameraSettingsDefaults(cameraSettings: BarcodeAr.recommendedCameraSettings),
            barcodeArFeedback: .default,
            viewDefaults: DefaultsBarcodeArView()
        )
    }()

    func toEncodable() -> [String: Any?] {
        [
            "RecommendedCameraSettings": recommendedCameraSettings.toEncodable(),
            "barcodeArFeedback": barcodeArFeedback.jsonString,
            "BarcodeArView": viewDefaults.toEncodable()
        ]
    }
}

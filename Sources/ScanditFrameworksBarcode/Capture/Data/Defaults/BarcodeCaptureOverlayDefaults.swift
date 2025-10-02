/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture
import ScanditFrameworksCore


struct BarcodeCaptureOverlayDefaults: DefaultsEncodable {
    func toEncodable() -> [String: Any?] {
        let defaultBrush = defaultBrush()
        
        return [
            "DefaultBrush": defaultBrush
        ]
    }

    private func defaultBrush() -> [String: Any?] {
        let settings = BarcodeCaptureSettings()
        let mode = BarcodeCapture(context: nil, settings: settings)
        let overlay = BarcodeCaptureOverlay(barcodeCapture: mode)
        return EncodableBrush(brush: overlay.brush).toEncodable()
    }
}

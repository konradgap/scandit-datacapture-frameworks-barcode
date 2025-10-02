/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture
import ScanditFrameworksCore

struct FrameworksBarcodeFindViewSettingsDefaults: DefaultsEncodable {
    let barcodeFindViewSettings: BarcodeFindViewSettings

    func toEncodable() -> [String: Any?] {
        [
            "progressBarStartColor": barcodeFindViewSettings.progressBarStartColor.sdcHexString,
            "progressBarFinishColor": barcodeFindViewSettings.progressBarFinishColor.sdcHexString
        ]
    }
}

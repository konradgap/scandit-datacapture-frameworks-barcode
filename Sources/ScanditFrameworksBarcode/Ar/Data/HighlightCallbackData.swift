/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2024- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture

class HighlightCallbackData {
    let barcode: Barcode
    let callback: ((any UIView & BarcodeArHighlight)?) -> Void

    init(barcode: Barcode, callback: @escaping ((any UIView & BarcodeArHighlight)?) -> Void) {
        self.barcode = barcode
        self.callback = callback
    }
}

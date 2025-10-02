/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2024- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture

class AnnotationCallbackData {
    let barcode: Barcode
    let callback: ((any UIView & BarcodeArAnnotation)?) -> Void

    init(barcode: Barcode, callback: @escaping ((any UIView & BarcodeArAnnotation)?) -> Void) {
        self.barcode = barcode
        self.callback = callback
    }
}

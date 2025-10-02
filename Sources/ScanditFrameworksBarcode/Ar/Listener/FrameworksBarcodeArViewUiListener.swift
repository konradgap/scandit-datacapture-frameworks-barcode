/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2024- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture
import UIKit
import ScanditFrameworksCore

public enum BarcodeArViewUiDelegateEvents: String, CaseIterable {
    case didTapHighlightForBarcodeEvent = "BarcodeArViewUiListener.didTapHighlightForBarcode"
}

open class FrameworksBarcodeArViewUiListener: NSObject, BarcodeArViewUIDelegate {
    private let emitter: Emitter
    private let viewId: Int

    public init(emitter: Emitter, viewId: Int) {
        self.emitter = emitter
        self.viewId = viewId
    }

    private let didTapHighlightForBarcode = Event(
        name: BarcodeArViewUiDelegateEvents.didTapHighlightForBarcodeEvent.rawValue
    )
    
    public func barcodeAr(_ barcodeAr: BarcodeAr, didTapHighlightFor barcode: Barcode, highlight: any UIView & BarcodeArHighlight) {
        didTapHighlightForBarcode.emit(on: emitter, payload: [
            "barcode": barcode.jsonString,
            "barcodeId": barcode.uniqueId,
            "viewId": self.viewId
        ])
    }
}

/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2024- Scandit AG. All rights reserved.
 */

import Foundation
import UIKit
import ScanditFrameworksCore
import ScanditBarcodeCapture

class FrameworksPopoverAnnotationDelegate: NSObject, BarcodeArPopoverAnnotationDelegate {
    private let emitter: Emitter
    private let viewId: Int

    public init(emitter: Emitter, viewId: Int) {
        self.emitter = emitter
        self.viewId = viewId
    }

    private let didTapPopoverButton = Event(
        name: FrameworksBarcodeArAnnotationEvents.didTapPopoverButton.rawValue
    )

    func barcodeArPopoverAnnotation(
        _ annotation: BarcodeArPopoverAnnotation, didTap button: BarcodeArPopoverAnnotationButton, at index: Int
    ) {
        didTapPopoverButton.emit(on: self.emitter, payload: [
            "barcodeId": annotation.barcode.uniqueId,
            "buttonIndex": index,
            "viewId": self.viewId
        ])
    }

    private let didTapPopover = Event(
        name: FrameworksBarcodeArAnnotationEvents.didTapPopover.rawValue
    )

    func barcodeArPopoverAnnotationDidTap(_ annotation: BarcodeArPopoverAnnotation) {
        didTapPopover.emit(on: self.emitter, payload: [
            "barcodeId": annotation.barcode.uniqueId,
            "viewId": self.viewId
        ])
    }
}

/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture
import ScanditFrameworksCore

open class FrameworksBarcodeBatchBasicOverlayListener: NSObject, BarcodeBatchBasicOverlayDelegate {
    private let emitter: Emitter
    
    public init(emitter: Emitter) {
        self.emitter = emitter
    }
    
    private let brushForTrackedBarcodeEvent = Event(.brushForTrackedBarcode)
    private let didTapOnTrackedBarcodeEvent = Event(.didTapOnTrackedBarcode)
    
    public func barcodeBatchBasicOverlay(_ overlay: BarcodeBatchBasicOverlay,
                                         brushFor trackedBarcode: TrackedBarcode) -> Brush? {
        guard emitter.hasListener(for: brushForTrackedBarcodeEvent) else { return overlay.brush }
        brushForTrackedBarcodeEvent.emit(on: emitter,
                                         payload: ["trackedBarcode": trackedBarcode.jsonString])
        return nil
    }
    
    public func barcodeBatchBasicOverlay(_ overlay: BarcodeBatchBasicOverlay,
                                         didTap trackedBarcode: TrackedBarcode) {
        guard emitter.hasListener(for: didTapOnTrackedBarcodeEvent) else { return }
        didTapOnTrackedBarcodeEvent.emit(on: emitter,
                                         payload: ["trackedBarcode": trackedBarcode.jsonString])
    }
}

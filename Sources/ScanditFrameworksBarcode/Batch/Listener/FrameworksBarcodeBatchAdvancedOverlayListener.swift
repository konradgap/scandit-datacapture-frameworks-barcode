/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture
import ScanditFrameworksCore

open class FrameworksBarcodeBatchAdvancedOverlayListener: NSObject, BarcodeBatchAdvancedOverlayDelegate {
    private let emitter: Emitter

    public init(emitter: Emitter) {
        self.emitter = emitter
    }

    private let offsetForTrackedBarcodeEvent = Event(.offsetForTrackedBarcode)
    private let anchorForTrackedBarcodeEvent = Event(.anchorForTrackedBarcode)
    private let widgetForTrackedBarcodeEvent = Event(.widgetForTrackedBarcode)

    public func barcodeBatchAdvancedOverlay(_ overlay: BarcodeBatchAdvancedOverlay,
                                               viewFor trackedBarcode: TrackedBarcode) -> UIView? {
        if emitter.hasListener(for: widgetForTrackedBarcodeEvent) {
            widgetForTrackedBarcodeEvent.emit(on: emitter,
                                              payload: ["trackedBarcode": trackedBarcode.jsonString])
        }
        return nil
    }

    public func barcodeBatchAdvancedOverlay(_ overlay: BarcodeBatchAdvancedOverlay,
                                               anchorFor trackedBarcode: TrackedBarcode) -> Anchor {
        if emitter.hasListener(for: anchorForTrackedBarcodeEvent) {
            anchorForTrackedBarcodeEvent.emit(on: emitter,
                                              payload: ["trackedBarcode": trackedBarcode.jsonString])
        }
        return .center
    }

    public func barcodeBatchAdvancedOverlay(_ overlay: BarcodeBatchAdvancedOverlay,
                                               offsetFor trackedBarcode: TrackedBarcode) -> PointWithUnit {
        if emitter.hasListener(for: offsetForTrackedBarcodeEvent) {
            offsetForTrackedBarcodeEvent.emit(on: emitter,
                                              payload: ["trackedBarcode": trackedBarcode.jsonString])
        }
        return .zero
    }
}

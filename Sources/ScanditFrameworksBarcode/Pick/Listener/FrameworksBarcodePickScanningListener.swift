/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */


import ScanditBarcodeCapture
import ScanditFrameworksCore

public enum BarcodePickScanningEvent: String, CaseIterable {
    case didUpdateScanningSession = "BarcodePickScanningListener.didUpdateScanningSession"
    case didCompleteScanningSession = "BarcodePickScanningListener.didCompleteScanningSession"
}

open class FrameworksBarcodePickScanningListener : NSObject, BarcodePickScanningListener {
    private let emitter: Emitter
    private let viewId: Int

    public init(emitter: Emitter, viewId: Int) {
        self.emitter = emitter
        self.viewId = viewId
    }

    public func barcodePick(_ barcodePick: BarcodePick, didComplete scanningSession: BarcodePickScanningSession) {
        guard emitter.hasViewSpecificListenersForEvent(viewId, for: BarcodePickScanningEvent.didCompleteScanningSession.rawValue) else { return }

        emitter.emit(name: BarcodePickScanningEvent.didCompleteScanningSession.rawValue, payload: ["session": scanningSession.jsonString, "viewId": self.viewId])
    }

    public func barcodePick(_ barcodePick: BarcodePick, didUpdate scanningSession: BarcodePickScanningSession) {
        guard emitter.hasViewSpecificListenersForEvent(viewId, for: BarcodePickScanningEvent.didUpdateScanningSession.rawValue) else { return }

        emitter.emit(name: BarcodePickScanningEvent.didUpdateScanningSession.rawValue, payload: ["session": scanningSession.jsonString, "viewId": self.viewId])
    }
}

/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */


import ScanditBarcodeCapture
import ScanditFrameworksCore

public enum BarcodePickViewListenerEvents: String, CaseIterable {
    case didStartScanning = "BarcodePickViewListener.didStartScanning"
    case didFreezeScanning = "BarcodePickViewListener.didFreezeScanning"
    case didPauseScanning = "BarcodePickViewListener.didPauseScanning"
    case didStopScanning = "BarcodePickViewListener.didStopScanning"
}

open class FrameworksBarcodePickViewListener : NSObject, BarcodePickViewListener {
    private let emitter: Emitter
    private let viewId: Int

    public init(emitter: Emitter, viewId: Int) {
        self.emitter = emitter
        self.viewId = viewId
    }

    public func barcodePickViewDidFreezeScanning(_ view: BarcodePickView) {
        guard emitter.hasViewSpecificListenersForEvent(viewId, for: BarcodePickViewListenerEvents.didFreezeScanning.rawValue) else { return }
        emitter.emit(name: BarcodePickViewListenerEvents.didFreezeScanning.rawValue, payload: ["viewId": self.viewId])
    }

    public func barcodePickViewDidStopScanning(_ view: BarcodePickView) {
        guard emitter.hasViewSpecificListenersForEvent(viewId, for: BarcodePickViewListenerEvents.didStopScanning.rawValue) else { return }
        emitter.emit(name: BarcodePickViewListenerEvents.didStopScanning.rawValue, payload: ["viewId": self.viewId])
    }

    public func barcodePickViewDidPauseScanning(_ view: BarcodePickView) {
        guard emitter.hasViewSpecificListenersForEvent(viewId, for: BarcodePickViewListenerEvents.didPauseScanning.rawValue) else { return }
        emitter.emit(name: BarcodePickViewListenerEvents.didPauseScanning.rawValue, payload: ["viewId": self.viewId])
    }

    public func barcodePickViewDidStartScanning(_ view: BarcodePickView) {
        guard emitter.hasViewSpecificListenersForEvent(viewId, for: BarcodePickViewListenerEvents.didStartScanning.rawValue) else { return }
        emitter.emit(name: BarcodePickViewListenerEvents.didStartScanning.rawValue, payload: ["viewId": self.viewId])
    }
}

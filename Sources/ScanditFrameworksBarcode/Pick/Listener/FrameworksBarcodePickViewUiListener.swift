/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */


import ScanditBarcodeCapture
import ScanditFrameworksCore

public enum BarcodePickViewUiListenerEvents: String, CaseIterable {
    case didTapFinishButton = "BarcodePickViewUiListener.didTapFinishButton"
}

open class FrameworksBarcodePickViewUiListener : NSObject, BarcodePickViewUIDelegate {
    private let emitter: Emitter
    private let viewId: Int

    public init(emitter: Emitter, viewId: Int) {
        self.emitter = emitter
        self.viewId = viewId
    }

    public func barcodePickViewDidTapFinishButton(_ view: BarcodePickView) {
        guard emitter.hasViewSpecificListenersForEvent(viewId, for: BarcodePickViewUiListenerEvents.didTapFinishButton.rawValue) else { return }
        emitter.emit(name: BarcodePickViewUiListenerEvents.didTapFinishButton.rawValue, payload: ["viewId": self.viewId])
    }
}

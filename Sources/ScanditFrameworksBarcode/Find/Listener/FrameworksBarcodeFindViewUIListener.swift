/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditFrameworksCore
import ScanditBarcodeCapture

open class FrameworksBarcodeFindViewUIListener: NSObject, BarcodeFindViewUIDelegate {
    private let emitter: Emitter
    private let viewId: Int
    private let didTapFinishButtonEvent = Event(.finishButtonTapped)

    public init(emitter: Emitter, viewId: Int) {
        self.emitter = emitter
        self.viewId = viewId
    }

    public func barcodeFindView(_ view: BarcodeFindView,
                                didTapFinishButton foundItems: Set<BarcodeFindItem>) {
        guard emitter.hasViewSpecificListenersForEvent(viewId, for: .finishButtonTapped) else { return }
        let foundItemsBarcodeData = foundItems.map { $0.searchOptions.barcodeData }
        didTapFinishButtonEvent.emit(on: emitter, payload: ["foundItems": foundItemsBarcodeData, "viewId": self.viewId])
    }
}

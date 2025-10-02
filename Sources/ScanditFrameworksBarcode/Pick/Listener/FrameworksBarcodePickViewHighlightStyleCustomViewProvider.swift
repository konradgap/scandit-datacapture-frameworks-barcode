/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture
import ScanditFrameworksCore

public enum BarcodePickViewHighlightStyleCustomViewProviderEvent: String, CaseIterable {
    case viewForRequest = "BarcodePickViewHighlightStyleCustomViewProvider.viewForRequest"
}

open class FrameworksBarcodePickViewHighlightStyleCustomViewProvider: NSObject, BarcodePickViewHighlightStyleCustomViewDelegate {

    private let emitter: Emitter
    private let viewId: Int
    private let cache: ConcurrentDictionary<Int, (BarcodePickHighlightCustomViewResponse?) -> Void> = ConcurrentDictionary()

    public init(emitter: Emitter, viewId: Int) {
        self.emitter = emitter
        self.viewId = viewId
    }

    public func customView(
        for request: BarcodePickHighlightStyleRequest,
        completionHandler: @escaping (BarcodePickHighlightCustomViewResponse?) -> Void
    ) {
        guard emitter.hasViewSpecificListenersForEvent(viewId, for: BarcodePickViewHighlightStyleCustomViewProviderEvent.viewForRequest.rawValue) else { return }
        let requestId = request.hashValue
        emitter.emit(name: BarcodePickViewHighlightStyleCustomViewProviderEvent.viewForRequest.rawValue, payload: [
            "requestId": requestId,
            "request": request.jsonString,
            "viewId": self.viewId
        ])

        cache.setValue(completionHandler, for: requestId)

    }

    public func finishViewForRequest(requestId: Int, view: UIView?, statusIconStyle: BarcodePickStatusIconStyle?) {
        guard let completionHandler = cache.getValue(for: requestId) else {
            return
        }

        guard let view = view else {
            completionHandler(nil)
            return
        }

        completionHandler(BarcodePickHighlightCustomViewResponse(view: view, statusIconStyle: statusIconStyle))
    }

}

/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture
import ScanditFrameworksCore

public enum BarcodePickViewHighlightStyleAsyncProviderEvent: String, CaseIterable {
    case styleForRequest = "BarcodePickViewHighlightStyleAsyncProvider.styleForRequest"
}

open class FrameworksBarcodePickViewHighlightStyleAsyncProvider: NSObject, BarcodePickViewHighlightStyleDelegate {
    private let emitter: Emitter
    private let viewId: Int
    private let cache: ConcurrentDictionary<Int, (BarcodePickViewHighlightStyleResponse?) -> Void> = ConcurrentDictionary()

    public init(emitter: Emitter, viewId: Int) {
        self.emitter = emitter
        self.viewId = viewId
    }

    public func style(for request: BarcodePickHighlightStyleRequest, completionHandler: @escaping (BarcodePickViewHighlightStyleResponse?) -> Void) {
        guard emitter.hasViewSpecificListenersForEvent(viewId, for: BarcodePickViewHighlightStyleAsyncProviderEvent.styleForRequest.rawValue) else { return }
        let requestId = request.hashValue
        emitter.emit(name: BarcodePickViewHighlightStyleAsyncProviderEvent.styleForRequest.rawValue, payload: [
            "requestId": requestId,
            "request": request.jsonString,
            "viewId": self.viewId
        ])
        cache.setValue(completionHandler, for: requestId)
    }

    public func finishStyleForRequest(requestId: Int, responseJson: String?) {
        guard let completionHandler = cache.getValue(for: requestId) else {
            return
        }

        guard let responseJson = responseJson else {
            completionHandler(nil)
            return
        }

        completionHandler(BarcodePickViewHighlightStyleResponse(jsonString: responseJson))
    }

}

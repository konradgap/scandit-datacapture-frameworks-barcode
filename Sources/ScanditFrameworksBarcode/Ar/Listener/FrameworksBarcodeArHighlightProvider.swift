/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2024- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture
import ScanditFrameworksCore

public enum BarcodeArHighlightProviderEvents: String, CaseIterable {
    case highlightForBarcode = "BarcodeArHighlightProvider.highlightForBarcode"
}

open class FrameworksBarcodeArHighlightProvider: NSObject, BarcodeArHighlightProvider {

    private let emitter: Emitter
    private let viewId: Int
    private let parser: BarcodeArHighlightParser
    private let cache: BarcodeArAugmentationsCache

    public init(emitter: Emitter, viewId: Int, parser: BarcodeArHighlightParser, cache: BarcodeArAugmentationsCache) {
        self.emitter = emitter
        self.viewId = viewId
        self.parser = parser
        self.cache = cache
    }

    private let highlightForBarcode = Event(
        name: BarcodeArHighlightProviderEvents.highlightForBarcode.rawValue
    )

    public func highlight(
        for barcode: Barcode, completionHandler: @escaping ((any UIView & BarcodeArHighlight)?) -> Void
    ) {
        self.cache.addHighlightProviderCallback(
            barcodeId: barcode.uniqueId,
            callback: HighlightCallbackData(barcode: barcode, callback: completionHandler)
        )

        highlightForBarcode.emit(on: emitter, payload: [
            "barcode": barcode.jsonString,
            "barcodeId": barcode.uniqueId,
            "viewId": self.viewId
        ])
    }

    public func finishHighlightForBarcode(highlightJson: String) {
        let json = JSONValue(string: highlightJson)

        guard let barcodeId = json.optionalString(forKey: "barcodeId"),
              let callbackData = cache.getHighlightProviderCallback(barcodeId: barcodeId) else {
            return
        }

        if json.containsKey("highlight") == false {
            callbackData.callback(nil)
            return
        }

        let highlightJson = json.object(forKey: "highlight")

        if let highlight = self.parser.get(json: highlightJson, barcode: callbackData.barcode) {
            cache.addHighlight(barcodeId: barcodeId, highlight: highlight)
            callbackData.callback(highlight)
        }
    }

    public func updateHighlight(highlightJson: String) {
        let json = JSONValue(string: highlightJson)

        guard let barcodeId = json.optionalString(forKey: "barcodeId"),
              let highlight = cache.getHighlight(barcodeId: barcodeId) else {
            return
        }

        parser.updateHighlight(highlight, json: json)
    }
}

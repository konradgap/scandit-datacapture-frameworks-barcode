/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2024- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture
import ScanditFrameworksCore

public enum BarcodeArAnnotationProviderEvents: String, CaseIterable {
    case annotationForBarcode = "BarcodeArAnnotationProvider.annotationForBarcode"
}

open class FrameworksBarcodeArAnnotationProvider: NSObject, BarcodeArAnnotationProvider {

    private let emitter: Emitter
    private let viewId: Int
    private let parser: BarcodeArAnnotationParser
    private let cache: BarcodeArAugmentationsCache

    public init(emitter: Emitter, viewId: Int, parser: BarcodeArAnnotationParser, cache: BarcodeArAugmentationsCache) {
        self.emitter = emitter
        self.viewId = viewId
        self.parser = parser
        self.cache = cache
    }

    private let annotationForBarcode = Event(
        name: BarcodeArAnnotationProviderEvents.annotationForBarcode.rawValue
    )

    public func annotation(
        for barcode: Barcode, completionHandler: @escaping ((any UIView & BarcodeArAnnotation)?) -> Void
    ) {
        self.cache.addAnnotationProviderCallback(
            barcodeId: barcode.uniqueId,
            callback: AnnotationCallbackData(barcode: barcode, callback: completionHandler)
        )

        annotationForBarcode.emit(on: emitter, payload: [
            "barcode": barcode.jsonString,
            "barcodeId": barcode.uniqueId,
            "viewId": self.viewId
        ])
    }

    public func finishAnnotationForBarcode(annotationJson: String) {
        let json =  JSONValue(string: annotationJson)

        guard let barcodeId = json.optionalString(forKey: "barcodeId"),
              let callbackData = cache.getAnnotationProviderCallback(barcodeId: barcodeId) else {
            return
        }

        if json.containsKey("annotation") == false {
            callbackData.callback(nil)
            return
        }

        let annotationJson = json.object(forKey: "annotation")

        if let annotation = self.parser.get(json: annotationJson, barcode: callbackData.barcode) {
            cache.addAnnotation(barcodeId: barcodeId, annotation: annotation)
            callbackData.callback(annotation)
        }
    }

    public func updateAnnotation(annotationJson: String) {
        let json = JSONValue(string: annotationJson)

        guard let barcodeId = json.optionalString(forKey: "barcodeId") else {
            Log.error("Invalid update call received. BarcodeId was not present in the json.")
            return
        }

        guard let annotation = cache.getAnnotation(barcodeId: barcodeId) else {
            return
        }

        parser.updateAnnotation(annotation, json: json)
    }

    public func updateBarcodeArPopoverButtonAtIndex(updateJson: String) {
        let json = JSONValue(string: updateJson)

        guard let barcodeId = json.optionalString(forKey: "barcodeId"),
              let annotation = cache.getAnnotation(barcodeId: barcodeId) as? BarcodeArPopoverAnnotation else {
            return
        }

        let buttonJson = json.object(forKey: "button")
        parser.updateBarcodeArPopoverButton(annotation, json: buttonJson)
    }

}

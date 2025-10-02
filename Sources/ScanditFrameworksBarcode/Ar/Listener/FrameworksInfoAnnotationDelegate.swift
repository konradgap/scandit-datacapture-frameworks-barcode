/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2024- Scandit AG. All rights reserved.
 */

import Foundation
import UIKit
import ScanditFrameworksCore
import ScanditBarcodeCapture

class FrameworksInfoAnnotationDelegate: NSObject, BarcodeArInfoAnnotationDelegate {

    private let emitter: Emitter
    private let viewId: Int

    public init(emitter: Emitter, viewId: Int) {
        self.emitter = emitter
        self.viewId = viewId
    }

    private let didTapInfoAnnotationHeader = Event(
        name: FrameworksBarcodeArAnnotationEvents.didTapInfoAnnotationHeader.rawValue
    )

    func barcodeArInfoAnnotationDidTapHeader(_ annotation: BarcodeArInfoAnnotation) {
        didTapInfoAnnotationHeader.emit(on: self.emitter, payload: [
            "barcodeId": annotation.barcode.uniqueId,
            "viewId": self.viewId
        ])
    }

    private let didTapInfoAnnotationFooter = Event(
        name: FrameworksBarcodeArAnnotationEvents.didTapInfoAnnotationFooter.rawValue
    )

    func barcodeArInfoAnnotationDidTapFooter(_ annotation: BarcodeArInfoAnnotation) {
        didTapInfoAnnotationFooter.emit(on: self.emitter, payload: [
            "barcodeId": annotation.barcode.uniqueId,
            "viewId": self.viewId
        ])
    }

    private let didTapInfoAnnotationLeftIcon = Event(
        name: FrameworksBarcodeArAnnotationEvents.didTapInfoAnnotationLeftIcon.rawValue
    )

    func barcodeArInfoAnnotation(
        _ annotation: BarcodeArInfoAnnotation,
        didTapLeftIconFor element: BarcodeArInfoAnnotationBodyComponent,
        at componentIndex: Int
    ) {
        didTapInfoAnnotationLeftIcon.emit(
            on: self.emitter,
            payload: [
                "barcodeId": annotation.barcode.uniqueId,
                "componentIndex": componentIndex,
                "viewId": self.viewId
            ]
        )
    }

    private let didTapInfoAnnotationRightIcon = Event(
        name: FrameworksBarcodeArAnnotationEvents.didTapInfoAnnotationRightIcon.rawValue
    )

    func barcodeArInfoAnnotation(
        _ annotation: BarcodeArInfoAnnotation,
        didTapRightIconFor element: BarcodeArInfoAnnotationBodyComponent,
        at componentIndex: Int
    ) {
        didTapInfoAnnotationRightIcon.emit(
            on: self.emitter,
            payload: [
                "barcodeId": annotation.barcode.uniqueId,
                "componentIndex": componentIndex,
                "viewId": self.viewId
            ]
        )
    }

    private let didTapInfoAnnotation = Event(
        name: FrameworksBarcodeArAnnotationEvents.didTapInfoAnnotation.rawValue
    )

    func barcodeArInfoAnnotationDidTap(_ annotation: BarcodeArInfoAnnotation) {
        didTapInfoAnnotation.emit(on: self.emitter, payload: [
            "barcodeId": annotation.barcode.uniqueId,
            "viewId": self.viewId
        ])
    }
}

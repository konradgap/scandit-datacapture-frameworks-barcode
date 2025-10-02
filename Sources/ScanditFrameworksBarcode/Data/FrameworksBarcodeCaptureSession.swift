/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import Foundation

import ScanditBarcodeCapture

public class FrameworksBarcodeCaptureSession {
    let frameSequenceId: Int
    let newlyRecognizedBarcode: Barcode?
    let newlyLocalizedBarcodes: [LocalizedOnlyBarcode]
    weak var captureSession: BarcodeCaptureSession?

    init(frameSequenceId: Int, newlyRecognizedBarcode: Barcode?, newlyLocalizedBarcodes: [LocalizedOnlyBarcode], captureSession: BarcodeCaptureSession?) {
        self.frameSequenceId = frameSequenceId
        self.newlyRecognizedBarcode = newlyRecognizedBarcode
        self.newlyLocalizedBarcodes = newlyLocalizedBarcodes
        self.captureSession = captureSession
    }

    static func fromCaptureSession(session: BarcodeCaptureSession) -> FrameworksBarcodeCaptureSession {
        return FrameworksBarcodeCaptureSession(
            frameSequenceId: session.frameSequenceId,
            newlyRecognizedBarcode: session.newlyRecognizedBarcode,
            newlyLocalizedBarcodes: session.newlyLocalizedBarcodes,
            captureSession: session
        )
    }
}

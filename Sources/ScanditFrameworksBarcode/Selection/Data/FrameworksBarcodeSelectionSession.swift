
/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import Foundation

import ScanditBarcodeCapture

internal class FrameworksBarcodeSelectionSession {
    let frameSequenceId: Int
    let selectedBarcodes: [Barcode]
    weak var selectionSession: BarcodeSelectionSession?

    init(frameSequenceId: Int, selectedBarcodes: [Barcode], selectionSession: BarcodeSelectionSession?) {
        self.frameSequenceId = frameSequenceId
        self.selectedBarcodes = selectedBarcodes
        self.selectionSession = selectionSession
    }

    static func fromSelectionSession(session: BarcodeSelectionSession) -> FrameworksBarcodeSelectionSession {
        return FrameworksBarcodeSelectionSession(
            frameSequenceId: session.frameSequenceId,
            selectedBarcodes: session.selectedBarcodes,
            selectionSession: session
        )
    }
}

/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import Foundation

import ScanditBarcodeCapture

public class FrameworksBarcodeBatchSession {
    let frameSequenceId: Int
    let trackedBarcodes: [Int: TrackedBarcode]
    weak var batchSession: BarcodeBatchSession?

    init(frameSequenceId: Int, trackedBarcodes: [Int: TrackedBarcode], batchSession: BarcodeBatchSession?) {
        self.frameSequenceId = frameSequenceId
        self.trackedBarcodes = trackedBarcodes
        self.batchSession = batchSession
    }

    static func fromBatchSession(session: BarcodeBatchSession) -> FrameworksBarcodeBatchSession {
        return FrameworksBarcodeBatchSession(
            frameSequenceId: session.frameSequenceId,
            trackedBarcodes: session.trackedBarcodes,
            batchSession: session
        )
    }
}

/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture
import ScanditFrameworksCore

open class FrameworksBarcodeCountCaptureListListener: NSObject, BarcodeCountCaptureListListener {
    private enum Constants {
        static let sessionUpdated = "BarcodeCountCaptureListListener.didUpdateSession"
    }

    private let emitter: Emitter
    private let viewId: Int
    private let sessionUpdatedEvent = Event(name: Constants.sessionUpdated)

    public init(emitter: Emitter, viewId: Int) {
        self.emitter = emitter
        self.viewId = viewId
    }

    public func captureList(_ captureList: BarcodeCountCaptureList,
                            didUpdate session: BarcodeCountCaptureListSession) {
        sessionUpdatedEvent.emit(on: emitter, payload: ["session": session.jsonString, "viewId": self.viewId])
    }
}

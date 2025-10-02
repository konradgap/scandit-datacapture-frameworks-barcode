/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture
import ScanditFrameworksCore

public enum BarcodePickListenerEvent: String, CaseIterable {
    case didUpdateSession = "BarcodePickListener.didUpdateSession"
}

open class FrameworksBarcodePickListener: NSObject, BarcodePickListener {
    private let emitter: Emitter
    private let viewId: Int
    private var events: [String: (Bool) -> Void] = [:]
    private let coordinator = ReadWriteCoordinator()

    public init(emitter: Emitter, viewId: Int) {
        self.emitter = emitter
        self.viewId = viewId
    }

    public func barcodePick(_ barcodePick: BarcodePick, didUpdate session: BarcodePickSession) {
        guard emitter.hasViewSpecificListenersForEvent(viewId, for: BarcodePickListenerEvent.didUpdateSession.rawValue) else { return }
        emitter.emit(
            name: BarcodePickListenerEvent.didUpdateSession.rawValue,
            payload: [
                "session": session.jsonString,
                "viewId": self.viewId
            ]
        )
    }
}

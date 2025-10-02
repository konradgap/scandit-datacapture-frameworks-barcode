/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2024- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture
import ScanditFrameworksCore

public enum BarcodeArListenerEvents: String, CaseIterable {
    case didUpdateSession = "BarcodeArListener.didUpdateSession"
}

fileprivate extension Event {
    init(_ event: BarcodeArListenerEvents) {
        self.init(name: event.rawValue)
    }
}

fileprivate extension Emitter {
    func hasListener(for event: BarcodeArListenerEvents) -> Bool {
        hasListener(for: event.rawValue)
    }

    func hasViewSpecificListenersForEvent(_ viewId: Int, for event: String) -> Bool {
        hasListener(for: "\(event).\(viewId)")
    }
}

open class FrameworksBarcodeArListener: NSObject, BarcodeArListener {
    private let emitter: Emitter
    private let viewId: Int

    private let sessionUpdatedEvent = EventWithResult<Bool>(event: Event(BarcodeArListenerEvents.didUpdateSession))

    private var latestSession: BarcodeArSession?

    private let cache: BarcodeArAugmentationsCache

    public init(emitter: Emitter, viewId: Int, cache: BarcodeArAugmentationsCache) {
        self.emitter = emitter
        self.viewId = viewId
        self.cache = cache
    }

    public func barcodeAr(
        _ barcodeAr: BarcodeAr, didUpdate session: BarcodeArSession, frameData: any FrameData
    ) {
        guard emitter.hasViewSpecificListenersForEvent(viewId, for: BarcodeArListenerEvents.didUpdateSession.rawValue) else { return }
        latestSession = session
        cache.updateFromSession(session)

        let frameId = LastFrameData.shared.addToCache(frameData: frameData)

        sessionUpdatedEvent.emit(
            on: emitter,
            payload: [
                "session": session.jsonString,
                "frameId": frameId,
                "viewId": self.viewId
            ]
        )

        LastFrameData.shared.removeFromCache(frameId: frameId)
    }

    public func finishDidUpdateSession(enabled: Bool) {
        sessionUpdatedEvent.unlock(value: enabled)
    }

    public func resetSession() {
        latestSession?.reset()
        sessionUpdatedEvent.reset()
    }
}

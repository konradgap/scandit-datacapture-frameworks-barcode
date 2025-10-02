/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture
import ScanditFrameworksCore

public enum FrameworksBarcodeBatchEvent: String, CaseIterable {
    case inCallback = "BarcodeBatchListener.inCallback"
    case sessionUpdated = "BarcodeBatchListener.didUpdateSession"
    case brushForTrackedBarcode = "BarcodeBatchBasicOverlayListener.brushForTrackedBarcode"
    case didTapOnTrackedBarcode = "BarcodeBatchBasicOverlayListener.didTapTrackedBarcode"
    case offsetForTrackedBarcode = "BarcodeBatchAdvancedOverlayListener.offsetForTrackedBarcode"
    case anchorForTrackedBarcode = "BarcodeBatchAdvancedOverlayListener.anchorForTrackedBarcode"
    case widgetForTrackedBarcode = "BarcodeBatchAdvancedOverlayListener.viewForTrackedBarcode"
    case didTapViewForTrackedBarcode = "BarcodeBatchAdvancedOverlayListener.didTapViewForTrackedBarcode"
}

internal extension Event {
    init(_ event: FrameworksBarcodeBatchEvent) {
        self.init(name: event.rawValue)
    }
}

internal extension Emitter {
    func hasListener(for event: FrameworksBarcodeBatchEvent) -> Bool {
        hasListener(for: event.rawValue)
    }
}

open class FrameworksBarcodeBatchListener: NSObject, BarcodeBatchListener {
    internal let emitter: Emitter
    private let cachedBatchSession: AtomicValue<FrameworksBarcodeBatchSession?>
    private let modeId: Int
    private let isEnabled: AtomicValue<Bool> = AtomicValue(false)

    public init(emitter: Emitter, modeId: Int, cachedBatchSession: AtomicValue<FrameworksBarcodeBatchSession?>) {
        self.emitter = emitter
        self.modeId = modeId
        self.cachedBatchSession = cachedBatchSession
    }

    private let sessionUpdatedEvent = EventWithResult<Bool>(event: Event(.sessionUpdated))

    public func barcodeBatch(_ barcodeBatch: BarcodeBatch,
                                didUpdate session: BarcodeBatchSession,
                                frameData: FrameData) {
        self.cachedBatchSession.value = FrameworksBarcodeBatchSession.fromBatchSession(session: session)
        
        if !isEnabled.value {
            return
        }

        let frameId = LastFrameData.shared.addToCache(frameData: frameData)
        
        let payload =  [
            "session": session.jsonString,
            "frameId": frameId,
            "modeId": modeId
        ] as [String : Any?]

        sessionUpdatedEvent.emit(
            on: emitter,
            payload: payload
        )
        
        LastFrameData.shared.removeFromCache(frameId: frameId)
    }

    public func finishDidUpdateSession(enabled: Bool) {
        sessionUpdatedEvent.unlock(value: enabled)
    }

    public func resetSession(with frameSequenceId: Int?) {
        guard
            let session = self.cachedBatchSession.value,
            frameSequenceId == nil || session.frameSequenceId == frameSequenceId else { return }
        session.batchSession?.reset()
    }

    public func reset() {
        self.cachedBatchSession.value = nil
        sessionUpdatedEvent.reset()
    }
    
    public func setEnabled(enabled: Bool) {
        isEnabled.value = enabled
    }
}

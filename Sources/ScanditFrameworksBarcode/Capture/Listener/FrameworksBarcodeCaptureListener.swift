/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture
import ScanditFrameworksCore

public enum FrameworksBarcodeCaptureEvent: String, CaseIterable {
    case barcodeScanned = "BarcodeCaptureListener.didScan"
    case sessionUpdated = "BarcodeCaptureListener.didUpdateSession"
}

fileprivate extension Event {
    init(_ event: FrameworksBarcodeCaptureEvent) {
        self.init(name: event.rawValue)
    }
}

fileprivate extension Emitter {
    func hasListener(for event: FrameworksBarcodeCaptureEvent) -> Bool {
        hasListener(for: event.rawValue)
    }
}

open class FrameworksBarcodeCaptureListener: NSObject, BarcodeCaptureListener {
    internal let emitter: Emitter
    private let cachedCaptureSession: AtomicValue<FrameworksBarcodeCaptureSession?>
    private let modeId: Int

    public init(emitter: Emitter, modeId: Int, cachedCaptureSession: AtomicValue<FrameworksBarcodeCaptureSession?>) {
        self.emitter = emitter
        self.modeId = modeId
        self.cachedCaptureSession = cachedCaptureSession
    }

    private let barcodeScannedEvent = EventWithResult<Bool>(event: Event(FrameworksBarcodeCaptureEvent.barcodeScanned))
    private let sessionUpdatedEvent = EventWithResult<Bool>(event: Event(FrameworksBarcodeCaptureEvent.sessionUpdated))

    public func barcodeCapture(_ barcodeCapture: BarcodeCapture,
                        didScanIn session: BarcodeCaptureSession,
                        frameData: FrameData) {
        self.cachedCaptureSession.value = FrameworksBarcodeCaptureSession.fromCaptureSession(session: session)

        let frameId = LastFrameData.shared.addToCache(frameData: frameData)

        let payload = [
            "session": session.jsonString,
            "frameId": frameId,
            "modeId": modeId
        ] as [String : Any?]

        barcodeScannedEvent.emit(
            on: emitter,
            payload: payload
        )

        LastFrameData.shared.removeFromCache(frameId: frameId)
    }

    public func barcodeCapture(_ barcodeCapture: BarcodeCapture,
                        didUpdate session: BarcodeCaptureSession,
                        frameData: FrameData) {
        self.cachedCaptureSession.value = FrameworksBarcodeCaptureSession.fromCaptureSession(session: session)

        let frameId = LastFrameData.shared.addToCache(frameData: frameData)

        let payload = [
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

    public func finishDidScan(enabled: Bool) {
        barcodeScannedEvent.unlock(value: enabled)
    }

    public func resetSession(with frameSequenceId: Int?) {
        guard
            let session = self.cachedCaptureSession.value,
            frameSequenceId == nil || session.frameSequenceId == frameSequenceId else { return }
        session.captureSession?.reset()
    }

    public func reset() {
        self.cachedCaptureSession.value = nil
        sessionUpdatedEvent.reset()
        barcodeScannedEvent.reset()
    }
}

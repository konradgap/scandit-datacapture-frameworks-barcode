/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture
import ScanditFrameworksCore

extension Barcode {
    var selectionIdentifier: String {
        return "\(data ?? "")\(SymbologyDescription(symbology: symbology).identifier)"
    }
}

public enum FrameworksBarcodeSelectionEvent: String, CaseIterable {
    case didUpdateSelection = "BarcodeSelectionListener.didUpdateSelection"
    case didUpdateSession = "BarcodeSelectionListener.didUpdateSession"
    case brushForAimedBarcode = "BarcodeSelectionAimedBrushProvider.brushForBarcode"
    case brushForTrackedBarcode = "BarcodeSelectionTrackedBrushProvider.brushForBarcode"
}

fileprivate extension Event {
    init(_ event: FrameworksBarcodeSelectionEvent) {
        self.init(name: event.rawValue)
    }
}

fileprivate extension Emitter {
    func hasListener(for event: FrameworksBarcodeSelectionEvent) -> Bool {
        hasListener(for: event.rawValue)
    }
}

open class FrameworksBarcodeSelectionListener: NSObject, BarcodeSelectionListener {
    private let emitter: Emitter
    private let modeId: Int

    private let didUpdateSelectionEvent = EventWithResult<Bool>(event: Event(.didUpdateSelection))
    private let didUpdateSessionEvent = EventWithResult<Bool>(event: Event(FrameworksBarcodeSelectionEvent.didUpdateSession))

    private var lastSession: FrameworksBarcodeSelectionSession?

    public init(emitter: Emitter,
                modeId: Int) {
        self.emitter = emitter
        self.modeId = modeId
    }

    public func finishDidSelect(enabled: Bool) {
        didUpdateSelectionEvent.unlock(value: enabled)
    }

    public func finishDidUpdate(enabled: Bool) {
        didUpdateSessionEvent.unlock(value: enabled)
    }

    public func getBarcodeCount(selectionIdentifier: String) -> Int {
        let selector: (Barcode) -> Bool = { $0.selectionIdentifier == selectionIdentifier }
        guard let session = lastSession,
              let barcode = session.selectedBarcodes.first(where: selector) else { return 0 }
        return (session.selectionSession?.count(for: barcode)) ?? 0
    }

    public func resetSession(frameSequenceId: Int?) {
        guard let session = lastSession,
              let frameSequenceId = frameSequenceId,
              session.frameSequenceId == frameSequenceId else { return }
        session.selectionSession?.reset()
    }

    public func barcodeSelection(_ barcodeSelection: BarcodeSelection,
                                 didUpdateSelection session: BarcodeSelectionSession,
                                 frameData: FrameData?) {
        lastSession = FrameworksBarcodeSelectionSession.fromSelectionSession(session: session)
        
        var frameId: String? = nil
        
        if let data = frameData {
            frameId = LastFrameData.shared.addToCache(frameData: data)
        }

        didUpdateSelectionEvent.emit(
            on: emitter,
            payload: [
                "session": session.jsonString,
                "frameId": frameId,
                "modeId": modeId,
            ]
        )
        
        if let id = frameId {
            LastFrameData.shared.removeFromCache(frameId: id)
        }
    }

    public func barcodeSelection(_ barcodeSelection: BarcodeSelection,
                                 didUpdate session: BarcodeSelectionSession,
                                 frameData: FrameData?) {
        lastSession = FrameworksBarcodeSelectionSession.fromSelectionSession(session: session)
        var frameId: String? = nil
        
        if let data = frameData {
            frameId = LastFrameData.shared.addToCache(frameData: data)
        }

        didUpdateSessionEvent.emit(
            on: emitter,
            payload: [
                "session": session.jsonString,
                "frameId": frameId,
                "modeId": modeId
            ]
        )
        
        if let id = frameId {
            LastFrameData.shared.removeFromCache(frameId: id)
        }
    }
    
    public func reset() {
        didUpdateSessionEvent.reset()
        didUpdateSelectionEvent.reset()
    }
}

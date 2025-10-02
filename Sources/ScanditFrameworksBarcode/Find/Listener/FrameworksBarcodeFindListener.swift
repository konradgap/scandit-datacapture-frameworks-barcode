/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditFrameworksCore
import ScanditBarcodeCapture

public enum FrameworksBarcodeFindEvent: String, CaseIterable {
    case didStartSearch = "BarcodeFindListener.onSearchStarted"
    case didPauseSearch = "BarcodeFindListener.onSearchPaused"
    case didStopSearch = "BarcodeFindListener.onSearchStopped"
    case didUpdateSession = "BarcodeFindListener.didUpdateSession"
    case finishButtonTapped = "BarcodeFindViewUiListener.onFinishButtonTapped"
    case transformBarcodeData = "BarcodeFindTransformer.transformBarcodeData"
}

extension Emitter {
    func hasViewSpecificListenersForEvent(_ viewId: Int, for event: FrameworksBarcodeFindEvent) -> Bool {
        return hasViewSpecificListenersForEvent(viewId, for: event.rawValue)
    }
}

extension Event {
    init(_ event: FrameworksBarcodeFindEvent) {
        self.init(name: event.rawValue)
    }
}

open class FrameworksBarcodeFindListener: NSObject, BarcodeFindListener {
    private let emitter: Emitter
    private let viewId: Int
    private let didStartSearchEvent = Event(.didStartSearch)
    private let didPauseSearchEvent = Event(.didPauseSearch)
    private let didStopSearchEvent = Event(.didStopSearch)
    private let didUpdateSessionEvent = Event(.didUpdateSession)

    public init(emitter: Emitter, viewId: Int) {
        self.emitter = emitter
        self.viewId = viewId
    }

    public func barcodeFindDidStartSearch(_ barcodeFind: BarcodeFind) {
        guard emitter.hasViewSpecificListenersForEvent(viewId, for: .didStartSearch) else { return }
        dispatchMain { [weak self] in
            guard let self else { return }
            self.didStartSearchEvent.emit(on: self.emitter, payload: ["viewId": self.viewId])
        }
    }

    public func barcodeFind(_ barcodeFind: BarcodeFind, didPauseSearch foundItems: Set<BarcodeFindItem>) {
        guard emitter.hasViewSpecificListenersForEvent(viewId, for: .didPauseSearch) else { return }
        let foundItemsBarcodeData = foundItems.map { $0.searchOptions.barcodeData }
        dispatchMain { [weak self] in
            guard let self else { return }
            self.didPauseSearchEvent.emit(on: self.emitter, payload: ["foundItems": foundItemsBarcodeData,
                                                                      "viewId": self.viewId])
        }
    }

    public func barcodeFind(_ barcodeFind: BarcodeFind, didStopSearch foundItems: Set<BarcodeFindItem>) {
        guard emitter.hasViewSpecificListenersForEvent(viewId, for: .didStopSearch) else { return }
        let foundItemsBarcodeData = foundItems.map { $0.searchOptions.barcodeData }
        dispatchMain { [weak self] in
            guard let self else { return }
            self.didStopSearchEvent.emit(on: self.emitter, payload: ["foundItems": foundItemsBarcodeData,
                                                                     "viewId": self.viewId])
        }
    }
    
    public func barcodeFind(_ barcodeFind: BarcodeFind, didUpdate session: BarcodeFindSession) {
        guard emitter.hasViewSpecificListenersForEvent(viewId, for: .didUpdateSession) else { return }
        didUpdateSessionEvent.emit(
            on: emitter,
            payload: [
                "session": session.jsonString,
                "viewId": self.viewId
            ]
        )

    }
}

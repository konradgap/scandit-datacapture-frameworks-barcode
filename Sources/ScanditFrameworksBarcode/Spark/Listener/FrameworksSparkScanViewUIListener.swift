/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture
import ScanditFrameworksCore

public enum FrameworksSparkScanViewUIEvent: String, CaseIterable  {
    case barcodeFindButtonTapped = "SparkScanViewUiListener.barcodeFindButtonTapped"
    case barcodeCountButtonTapped = "SparkScanViewUiListener.barcodeCountButtonTapped"
    case labelCaptureButtonTapped = "SparkScanViewUiListener.labelCaptureButtonTapped"
    case didChangeViewState = "SparkScanViewUiListener.didChangeViewState"
}

fileprivate extension Event {
    init(_ event: FrameworksSparkScanViewUIEvent) {
        self.init(name: event.rawValue)
    }
}

open class FrameworksSparkScanViewUIListener: NSObject, SparkScanViewUIDelegate {

    private let emitter: Emitter
    private let viewId: Int

    public init(emitter: Emitter, viewId: Int) {
        self.emitter = emitter
        self.viewId = viewId
    }

    private let didChangeViewStateEvent = Event(.didChangeViewState)
    private let barcodeFindButtonTappedEvent = Event(.barcodeFindButtonTapped)
    private let barcodeCountButtonTappedEvent = Event(.barcodeCountButtonTapped)
    private let labelCaptureButtonTappedEvent = Event(.labelCaptureButtonTapped)

    private var isEnabled = AtomicValue<Bool>()

    public func enable() {
        isEnabled.value = true
    }

    public func disable() {
        isEnabled.value = false
    }
    
    public func sparkScanView(_ view: SparkScanView, didChange viewState: SparkScanViewState) {
        guard isEnabled.value, emitter.hasViewSpecificListenersForEvent(viewId: viewId, for: didChangeViewStateEvent) else { return }
        didChangeViewStateEvent.emit(on: emitter, payload: ["state" : viewState.jsonString, "viewId": viewId])
    }

    public func barcodeCountButtonTapped(in view: SparkScanView) {
        guard isEnabled.value, emitter.hasViewSpecificListenersForEvent(viewId: viewId, for: barcodeCountButtonTappedEvent) else { return }
        barcodeCountButtonTappedEvent.emit(on: emitter, payload: ["viewId": viewId])
    }
    
    public func barcodeFindButtonTapped(in view: SparkScanView) {
        guard isEnabled.value, emitter.hasViewSpecificListenersForEvent(viewId: viewId, for: barcodeFindButtonTappedEvent) else { return }
        barcodeFindButtonTappedEvent.emit(on: emitter, payload: ["viewId": viewId])
    }
    
    public func labelCaptureButtonTapped(in view: SparkScanView) {
        guard isEnabled.value, emitter.hasViewSpecificListenersForEvent(viewId: viewId, for: labelCaptureButtonTappedEvent) else { return }
        labelCaptureButtonTappedEvent.emit(on: emitter, payload: ["viewId": viewId])
    }
}

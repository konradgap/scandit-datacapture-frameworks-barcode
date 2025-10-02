/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2024- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture
import ScanditFrameworksCore

public enum FrameworksSparkScanFeedbackDelegateEvent: String, CaseIterable {
    case feedbackForBarcode = "SparkScanFeedbackDelegate.feedbackForBarcode"
}

fileprivate extension Event {
    init(_ event: FrameworksSparkScanFeedbackDelegateEvent) {
        self.init(name: event.rawValue)
    }
}

fileprivate extension Emitter {
    func hasViewSpecificListenersForEvent(_ viewId: Int, for event: FrameworksSparkScanFeedbackDelegateEvent) -> Bool {
        hasViewSpecificListenersForEvent(viewId, for: event.rawValue)
    }
}


open class FrameworksSparkScanFeedbackDelegate : NSObject, SparkScanFeedbackDelegate {
    private let emitter: Emitter
    private let viewId: Int
    
    private let feedbackForBarcodeEvent = EventWithResult<String?>(event: Event(.feedbackForBarcode))

    public init(emitter: Emitter, viewId: Int) {
        self.emitter = emitter
        self.viewId = viewId
    }
    
    public func feedback(for barcode: Barcode) -> SparkScanBarcodeFeedback? {
        guard emitter.hasViewSpecificListenersForEvent(viewId, for: .feedbackForBarcode) else { return nil }
        guard let feedbackJson = feedbackForBarcodeEvent.emit(
            on: emitter, payload: ["barcode": barcode.jsonString, "viewId": viewId]) ?? nil else {
            return nil
        }
        
        do {
            return try SparkScanBarcodeFeedback(jsonString: feedbackJson)
        } catch {
            print(error)
            return nil
        }
    }
    
    public func submitFeedback(feedbackJson: String?) {
        feedbackForBarcodeEvent.unlock(value: feedbackJson)
    }
}

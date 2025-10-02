/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2024- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture
import ScanditFrameworksCore

public typealias BarcodeId = String
private typealias TrackedBarcodeId = Int

public class BarcodeArAugmentationsCache {
    private static let DELETION_DELAY: TimeInterval = 2.0

    private let instanceId = UUID().uuidString
    private var annotationsCache = ConcurrentDictionary<BarcodeId, BarcodeArAnnotation>()
    private var highlightsCache = ConcurrentDictionary<BarcodeId, BarcodeArHighlight>()
    private var trackedBarcodeCache = ConcurrentDictionary<TrackedBarcodeId, BarcodeId>()
    private var barcodeArHighlightProviderCallback = ConcurrentDictionary<BarcodeId, HighlightCallbackData>()
    private var barcodeArAnnotationProviderCallback = ConcurrentDictionary<BarcodeId, AnnotationCallbackData>()

    // The native SDK has implemented a mechanism where the items are not immediately removed from the cache but
    // only marked for deletion and deleted after a delay. We need to have the same mechanism in the frameworks to
    // avoid not finding annotations or highlights in our cache.
    private var markedForDeletion = ConcurrentDictionary<BarcodeId, Timer>()

    func updateFromSession(_ session: BarcodeArSession) {
        for trackedBarcode in session.addedTrackedBarcodes {
            cancelDeletion(for: trackedBarcode.barcode.uniqueId)
            trackedBarcodeCache.setValue(trackedBarcode.barcode.uniqueId, for: trackedBarcode.identifier)
        }

        for trackedBarcodeId in session.removedTrackedBarcodes {
            if let barcodeId = trackedBarcodeCache.removeValue(for: trackedBarcodeId) {
                scheduleDeletion(for: barcodeId)
            }
        }
    }

    private func scheduleDeletion(for barcodeId: BarcodeId) {
        if let existingTimer = markedForDeletion.removeValue(for: barcodeId) {
            existingTimer.invalidate()
        }

        let timer = Timer.scheduledTimer(withTimeInterval: Self.DELETION_DELAY, repeats: false) { [weak self] _ in
            self?.performDeletion(for: barcodeId)
        }
        markedForDeletion.setValue(timer, for: barcodeId)
    }

    private func performDeletion(for barcodeId: BarcodeId) {
        _ = annotationsCache.removeValue(for: barcodeId)
        _ = highlightsCache.removeValue(for: barcodeId)
        _ = barcodeArHighlightProviderCallback.removeValue(for: barcodeId)
        _ = barcodeArAnnotationProviderCallback.removeValue(for: barcodeId)
    }

    func cancelDeletion(for barcodeId: BarcodeId) {
        if let timer = markedForDeletion.removeValue(for: barcodeId) {
            timer.invalidate()
        }
    }

    func addHighlightProviderCallback(barcodeId: BarcodeId, callback: HighlightCallbackData) {
        barcodeArHighlightProviderCallback.setValue(callback, for: barcodeId)
    }

    func getHighlightProviderCallback(barcodeId: BarcodeId) -> HighlightCallbackData? {
        return barcodeArHighlightProviderCallback.getValue(for: barcodeId)
    }

    func addHighlight(barcodeId: BarcodeId, highlight: BarcodeArHighlight) {
        highlightsCache.setValue(highlight, for: barcodeId)
    }

    func getHighlight(barcodeId: BarcodeId) -> BarcodeArHighlight? {
        return highlightsCache.getValue(for: barcodeId)
    }

    func addAnnotationProviderCallback(barcodeId: BarcodeId, callback: AnnotationCallbackData) {
        barcodeArAnnotationProviderCallback.setValue(callback, for: barcodeId)
    }

    func getAnnotationProviderCallback(barcodeId: BarcodeId) -> AnnotationCallbackData? {
        return barcodeArAnnotationProviderCallback.getValue(for: barcodeId)
    }

    func addAnnotation(barcodeId: BarcodeId, annotation: BarcodeArAnnotation) {
        annotationsCache.setValue(annotation, for: barcodeId)
    }

    func getAnnotation(barcodeId: BarcodeId) -> BarcodeArAnnotation? {
        return annotationsCache.getValue(for: barcodeId)
    }

    func clear() {
        markedForDeletion.getAllValues().forEach { timer in
            timer.value.invalidate()
        }
        markedForDeletion.removeAllValues()
        trackedBarcodeCache.removeAllValues()
        annotationsCache.removeAllValues()
        highlightsCache.removeAllValues()
        barcodeArHighlightProviderCallback.removeAllValues()
        barcodeArAnnotationProviderCallback.removeAllValues()
    }
}

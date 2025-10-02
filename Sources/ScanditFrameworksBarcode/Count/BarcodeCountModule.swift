/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture
import ScanditFrameworksCore

open class BarcodeCountModule: NSObject, FrameworkModule, DeserializationLifeCycleObserver {
    private let emitter: Emitter
    private let captureContext = DefaultFrameworksCaptureContext.shared

    public init(emitter: Emitter) {
        self.emitter = emitter
    }

    private let viewCache = FrameworksViewsCache<FrameworksBarcodeCountView>()

    public func didStart() {
        DeserializationLifeCycleDispatcher.shared.attach(observer: self)
    }

    public func didStop() {
        DeserializationLifeCycleDispatcher.shared.detach(observer: self)
        viewCache.disposeAll()
    }

    public func didDisposeDataCaptureContext() {
        viewCache.disposeAll()
    }

    public let defaults: DefaultsEncodable = BarcodeCountDefaults.shared

    public func addViewFromJson(parent: UIView, viewJson: String, result: FrameworksResult) {
        let block = { [weak self] in
            guard let self = self else { return }
            guard let context = self.captureContext.context else {
                result.reject(error: ScanditFrameworksCoreError.nilDataCaptureContext)
                Log.error("Error during the barcode count view deserialization.\nError: The DataCaptureView has not been initialized yet.")
                return
            }
            
            do {
                
                let viewCreationParams = try BarcodeCountViewCreationData.fromJson(viewJson)
                
                if let existingView = viewCache.getView(viewId: viewCreationParams.viewId) {
                    existingView.dispose()
                    _ = viewCache.remove(viewId: existingView.viewId)
                }
                
                if let previousView = viewCache.getTopMost() {
                    previousView.hide()
                }
                
                let view = try FrameworksBarcodeCountView.create(
                    emitter: self.emitter,
                    parent: parent,
                    context: context,
                    viewCreationParams: viewCreationParams
                )
                viewCache.addView(view: view)
                result.success()
            } catch {
                Log.error("Unable to create the BarcodeCountView.", error: error)
                result.reject(error: error)
            }
        }
        dispatchMain(block)
    }

    public func updateBarcodeCountView(viewId: Int, viewJson: String, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        
        let block = { [weak self] in
            guard self != nil else { return }
            viewInstance.updateMode(modeJson: viewJson)
            result.success()
        }
        dispatchMain(block)
    }

    public func removeBarcodeCountView(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.remove(viewId: viewId) else {
            result.success()
            return
        }
        viewInstance.dispose()
        result.success()
    }

    public func addBarcodeCountStatusProvider(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        
        let block = { [weak self] in
            guard self != nil else { return }
            viewInstance.addBarcodeCountStatusProvider()
            result.success(result: nil)
        }
        dispatchMain(block)
    }

    public func updateBarcodeCount(viewId: Int, modeJson: String, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        
        viewInstance.updateMode(modeJson: modeJson)
        result.success(result: nil)
    }

    public func addBarcodeCountViewListener(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            return
        }
        dispatchMain { [weak self] in
            guard self != nil else { return }
            viewInstance.addBarcodeCountViewListener()
            result.success()
        }
    }

    public func removeBarcodeCountViewListener(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        
        dispatchMain { [weak self] in
            guard self != nil else { return }
            viewInstance.removeBarcodeCountViewListener()
            result.success()
        }
    }

    public func addBarcodeCountViewUiListener(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        
        dispatchMain { [weak self] in
            guard self != nil else { return }
            viewInstance.addBarcodeCountViewUiListener()
            result.success()
        }
    }

    public func removeBarcodeCountViewUiListener(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        
        dispatchMain { [weak self] in
            guard self != nil else { return }
            viewInstance.removeBarcodeCountViewUiListener()
            result.success()
        }
    }

    public func clearHighlights(viewId: Int) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            return
        }
        viewInstance.barcodeViewClearHighlights()
    }

    public func finishBrushForRecognizedBarcodeEvent(viewId: Int, brush: Brush?, trackedBarcodeId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        
        dispatchMain { [weak self] in
            guard self != nil else { return }
            viewInstance.finishBrushForRecognizedBarcodeEvent(brush: brush, trackedBarcodeId: trackedBarcodeId)
            result.success()
        }
    }

    public func finishBrushForRecognizedBarcodeNotInListEvent(viewId: Int, brush: Brush?, trackedBarcodeId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        
        dispatchMain { [weak self] in
            guard self != nil else { return }
            viewInstance.finishBrushForRecognizedBarcodeNotInListEvent(brush: brush, trackedBarcodeId: trackedBarcodeId)
            result.success()
        }
    }

    public func finishBrushForAcceptedBarcodeEvent(viewId: Int, brush: Brush?, trackedBarcodeId: Int) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            return
        }
        
        dispatchMain{ [weak self] in
            guard self != nil else { return }
            viewInstance.finishBrushForAcceptedBarcodeEvent(brush: brush, trackedBarcodeId: trackedBarcodeId)
        }
    }

    public func finishBrushForRejectedBarcodeEvent(viewId: Int, brush: Brush?, trackedBarcodeId: Int) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            return
        }
        
        dispatchMain{ [weak self] in
            guard self != nil else { return }
            viewInstance.finishBrushForRejectedBarcodeEvent(brush: brush, trackedBarcodeId: trackedBarcodeId)
        }
    }

    public func setBarcodeCountCaptureList(viewId: Int, barcodesJson: String) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            return
        }
        
        let jsonArray = JSONValue(string: barcodesJson).asArray()
        let targetBarcodes = Set((0...jsonArray.count() - 1).map { jsonArray.atIndex($0).asObject() }.map {
            TargetBarcode(data: $0.string(forKey: "data"), quantity: $0.integer(forKey: "quantity"))
        })
        
        viewInstance.setBarcodeCountCaptureList(targetBarcodes: targetBarcodes)
    }

    public func resetBarcodeCountSession(viewId: Int, frameSequenceId: Int?) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            return
        }
        viewInstance.resetBarcodeCountSession(frameSequenceId: frameSequenceId)
    }

    public func finishOnScan(viewId: Int, enabled: Bool) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            return
        }
        viewInstance.finishOnScan(enabled: enabled)
    }

    public func addBarcodeCountListener(viewId: Int) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            return
        }
        viewInstance.addBarcodeCountListener()
    }

    public func removeBarcodeCountListener(viewId: Int) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            return
        }
        viewInstance.removeBarcodeCountListener()
    }

    public func addAsyncBarcodeCountListener(viewId: Int) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            return
        }
        viewInstance.addAsyncBarcodeCountListener()
    }

    public func removeAsyncBarcodeCountListener(viewId: Int) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            return
        }
        viewInstance.removeAsyncBarcodeCountListener()
    }

    public func resetBarcodeCount(viewId: Int) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            return
        }
        viewInstance.resetBarcodeCount()
    }

    public func startScanningPhase(viewId: Int) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            return
        }
        viewInstance.startScanningPhase()
    }

    public func endScanningPhase(viewId: Int) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            return
        }
        viewInstance.endScanningPhase()
    }

    public func submitSpatialMap(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        result.success(result: viewInstance.getSpatialMap()?.jsonString)
    }

    public func submitSpatialMap(viewId: Int, expectedNumberOfRows: Int, expectedNumberOfColumns: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        result.success(
            result: viewInstance.getSpatialMap(
                expectedNumberOfRows: expectedNumberOfRows,
                expectedNumberOfColumns: expectedNumberOfColumns
            )?.jsonString
        )
    }

    public func setModeEnabled(viewId: Int, enabled: Bool) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            return
        }
        viewInstance.setModeEnabled(enabled)
    }

    public func isModeEnabled() -> Bool {
        return viewCache.getTopMost()?.isModeEnabled == true
    }

    public func updateFeedback(viewId: Int, feedbackJson: String, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        
        guard let jsonData = feedbackJson.data(using: .utf8) else {
            result.reject(code: "-1", message: "Invalid feedback json", details: nil)
            return
        }

        do {
            try viewInstance.updateFeedback(feedbackJsonData: jsonData)
            result.success()
        } catch let error {
            result.reject(error: error)
        }
    }

    public func submitBarcodeCountStatusProviderCallbackResult(viewId: Int, statusJson: String, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        
        viewInstance.submitBarcodeCountStatusProviderCallbackResult(statusJson: statusJson)
        result.success()
    }

    public func getLastFrameDataBytes(frameId: String, result: FrameworksResult) {
        LastFrameData.shared.getLastFrameDataBytes(frameId: frameId) {
            result.success(result: $0)
        }
    }
    
    public func disposeBarcodeCountView(viewId: Int) {
        viewCache.remove(viewId: viewId)?.dispose()
        
        if let previousView = viewCache.getTopMost() {
            previousView.show()
        }
    }
    
    public func showView(_ viewId: Int) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else { return }
        
        viewInstance.show()
    }
    
    public func hideView(_ viewId: Int) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else { return }
        
        viewInstance.hide()
    }
    
    public func getTopMostView() -> BarcodeCountView? {
        return viewCache.getTopMost()?.view
    }
}

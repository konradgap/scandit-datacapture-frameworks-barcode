/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import Foundation
import ScanditCaptureCore
import ScanditBarcodeCapture
import ScanditFrameworksCore
import UIKit

public class FrameworksBarcodeCountView: FrameworksBaseView {

    private let dataCaptureContext: DataCaptureContext
    private let barcodeCountListener: FrameworksBarcodeCountListener
    private let captureListListener: FrameworksBarcodeCountCaptureListListener
    private let viewListener: FrameworksBarcodeCountViewListener
    private let viewUiListener: FrameworksBarcodeCountViewUIListener
    private let statusProvider: FrameworksBarcodeCountStatusProvider
    private let modeDeserializer: BarcodeCountDeserializer
    private let viewDeserializer: BarcodeCountViewDeserializer

    private(set) var view: BarcodeCountView!
    private var mode: BarcodeCount!

    private var _viewId: Int = 0
    public var viewId: Int { _viewId }
    public var parentId: Int? { nil }

    private init(
        context: DataCaptureContext,
        barcodeCountListener: FrameworksBarcodeCountListener,
        captureListListener: FrameworksBarcodeCountCaptureListListener,
        viewListener: FrameworksBarcodeCountViewListener,
        viewUiListener: FrameworksBarcodeCountViewUIListener,
        statusProvider: FrameworksBarcodeCountStatusProvider,
        modeDeserializer: BarcodeCountDeserializer = BarcodeCountDeserializer(),
        viewDeserializer: BarcodeCountViewDeserializer = BarcodeCountViewDeserializer()
    ) {
        self.dataCaptureContext = context
        self.barcodeCountListener = barcodeCountListener
        self.captureListListener = captureListListener
        self.viewListener = viewListener
        self.viewUiListener = viewUiListener
        self.statusProvider = statusProvider
        self.modeDeserializer = modeDeserializer
        self.viewDeserializer = viewDeserializer
    }

    private func deserializeView(
        parent: UIView,
        viewCreationParams: BarcodeCountViewCreationData
    ) throws {
        _viewId = viewCreationParams.viewId
        do {
            mode = try modeDeserializer.mode(fromJSONString: viewCreationParams.modeJson, context: self.dataCaptureContext)
        } catch {
            // handle error
            return
        }
        postModeChanges(viewCreationParams)
        do {
            view = try viewDeserializer.view(fromJSONString: viewCreationParams.viewJson, barcodeCount: mode, context: self.dataCaptureContext)
        } catch {
            // handle error
            return
        }
        postViewChanges(viewCreationParams)
        view.tag = viewId
        parent.tag = viewId
        view.delegate = viewListener
        view.uiDelegate = viewUiListener
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        parent.addSubview(view)
        
    }

    private func postModeChanges(_ changeParams: BarcodeCountViewCreationData) {
        mode.isEnabled = changeParams.isModeEnabled
        if changeParams.hasModeListener {
            mode.addListener(barcodeCountListener)
        } else {
            mode.removeListener(barcodeCountListener)
        }
    }

    private func postViewChanges(_ changeParams: BarcodeCountViewCreationData) {
        if changeParams.hasUIListener {
            addBarcodeCountViewUiListener()
        } else {
            removeBarcodeCountViewUiListener()
        }
        if changeParams.hasViewListener {
            addBarcodeCountViewListener()
        } else {
            removeBarcodeCountViewListener()
        }
        if changeParams.hasStatusProvider {
            addBarcodeCountStatusProvider()
        }
    }

    public func updateView(viewJson: String) {
        do {
            let updateParams = try BarcodeCountViewCreationData.fromViewJsonOnly(viewJson)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                _ = try? self.viewDeserializer.update(self.view, fromJSONString: updateParams.viewJson)
                self.postViewChanges(updateParams)
            }
            
        } catch {
            Log.error("Failed to update view.", error: error)
        }
    }

    public func updateMode(modeJson: String) {
        do {
            let updateParams = try BarcodeCountViewCreationData.fromModeJsonOnly(modeJson)
            _ = try? modeDeserializer.updateMode(mode, fromJSONString: updateParams.modeJson)
            postModeChanges(updateParams)
        } catch {
            Log.error("Failed to update mode.", error: error)
        }
    }

    public func setBarcodeCountCaptureList(targetBarcodes: Set<TargetBarcode>) {
        let barcodeCountCaptureList = BarcodeCountCaptureList(listener: captureListListener, targetBarcodes: Set(targetBarcodes))
        mode.setCaptureList(barcodeCountCaptureList)
    }

    public func addBarcodeCountStatusProvider() {
        view.setStatusProvider(statusProvider)
    }

    public func addBarcodeCountViewListener() {
        view.delegate = viewListener
    }

    public func removeBarcodeCountViewListener() {
        view.delegate = nil
    }

    public func addBarcodeCountViewUiListener() {
        view.uiDelegate = viewUiListener
    }

    public func removeBarcodeCountViewUiListener() {
        view.uiDelegate = nil
    }

    public func barcodeViewClearHighlights() {
        view.clearHighlights()
    }

    public func finishBrushForRecognizedBarcodeEvent(brush: Brush?, trackedBarcodeId: Int) {
        if let trackedBarcode = viewListener.getTrackedBarcodeForBrush(with: trackedBarcodeId, for: .brushForRecognizedBarcode), let brush = brush {
            view.setBrush(brush, forRecognizedBarcode: trackedBarcode)
        }
    }

    public func finishBrushForRecognizedBarcodeNotInListEvent(brush: Brush?, trackedBarcodeId: Int) {
        if let trackedBarcode = viewListener.getTrackedBarcodeForBrush(with: trackedBarcodeId, for: .brushForRecognizedBarcodeNotInList), let brush = brush {
            view.setBrush(brush, forRecognizedBarcodeNotInList: trackedBarcode)
        }
    }

    public func finishBrushForAcceptedBarcodeEvent(brush: Brush?, trackedBarcodeId: Int) {
        if let trackedBarcode = viewListener.getTrackedBarcodeForBrush(with: trackedBarcodeId, for: .brushForAcceptedBarcode), let brush = brush {
            view.setBrush(brush, forAcceptedBarcode: trackedBarcode)
        }
    }

    public func finishBrushForRejectedBarcodeEvent(brush: Brush?, trackedBarcodeId: Int) {
        if let trackedBarcode = viewListener.getTrackedBarcodeForBrush(with: trackedBarcodeId, for: .brushForRejectedBarcode), let brush = brush {
            view.setBrush(brush, forRejectedBarcode: trackedBarcode)
        }
    }

    public func resetBarcodeCountSession(frameSequenceId: Int?) {
        barcodeCountListener.resetSession(frameSequenceId: frameSequenceId)
    }

    public func finishOnScan(enabled: Bool) {
        barcodeCountListener.finishDidScan(enabled: enabled)
    }

    public func addBarcodeCountListener() {
        mode.addListener(barcodeCountListener)
    }

    public func removeBarcodeCountListener() {
        mode.removeListener(barcodeCountListener)
    }

    public func addAsyncBarcodeCountListener() {
        mode.addListener(barcodeCountListener)
        barcodeCountListener.enableAsync()
    }

    public func removeAsyncBarcodeCountListener() {
        barcodeCountListener.disableAsync()
        mode.removeListener(barcodeCountListener)
    }

    public func resetBarcodeCount() {
        mode.reset()
    }

    public func startScanningPhase() {
        mode.startScanningPhase()
    }

    public func endScanningPhase() {
        mode.endScanningPhase()
    }

    public func hide() {
        dispatchMain {
            self.view.isHidden = true
        }
    }

    public func show() {
        dataCaptureContext.setMode(mode)
        mode.reset()
        dispatchMain {
            self.view.isHidden = false
            self.view.superview?.bringSubviewToFront(self.view)
        }
    }

    public func getSpatialMap() -> BarcodeSpatialGrid? {
        barcodeCountListener.getSpatialMap()
    }

    public func getSpatialMap(expectedNumberOfRows: Int, expectedNumberOfColumns: Int) -> BarcodeSpatialGrid? {
        barcodeCountListener.getSpatialMap(expectedNumberOfRows: expectedNumberOfRows, expectedNumberOfColumns: expectedNumberOfColumns)
    }

    public func setModeEnabled(_ enabled: Bool) {
        mode.isEnabled = enabled
    }

    public var isModeEnabled: Bool {
        mode.isEnabled
    }

    public func updateFeedback(feedbackJsonData: Data) throws {
        if let json = try JSONSerialization.jsonObject(with: feedbackJsonData, options: []) as? [String: Any] {
            let newFeedback = mode.feedback
            if let successData = json["success"] as? [String: Any] {
                if let success = successData.encodeToJSONString() {
                    newFeedback.success = try Feedback(fromJSONString: success)
                }
            }
            
            if let failureData = json["failure"] as? [String: Any] {
                if let failure = failureData.encodeToJSONString() {
                    newFeedback.failure = try Feedback(fromJSONString: failure)
                }
            }
            
            mode.feedback = newFeedback
        } else {
            throw NSError(domain: "Invalid JSON format when updating the feedback", code: 0, userInfo: nil)
        }
    }

    public func submitBarcodeCountStatusProviderCallbackResult(statusJson: String) {
        statusProvider.submitCallbackResult(resultJson: statusJson)
    }

    public static func create(
        emitter: Emitter,
        parent: UIView,
        context: DataCaptureContext,
        viewCreationParams: BarcodeCountViewCreationData
    ) throws -> FrameworksBarcodeCountView {
        let barcodeCountListener = FrameworksBarcodeCountListener(emitter: emitter, viewId: viewCreationParams.viewId)
        let captureListListener = FrameworksBarcodeCountCaptureListListener(emitter: emitter, viewId: viewCreationParams.viewId)
        let viewListener = FrameworksBarcodeCountViewListener(emitter: emitter, viewId: viewCreationParams.viewId)
        let viewUiListener = FrameworksBarcodeCountViewUIListener(emitter: emitter, viewId: viewCreationParams.viewId)
        let statusProvider = FrameworksBarcodeCountStatusProvider(emitter: emitter, viewId: viewCreationParams.viewId)
        let instance = FrameworksBarcodeCountView(
            context: context,
            barcodeCountListener: barcodeCountListener,
            captureListListener: captureListListener,
            viewListener: viewListener,
            viewUiListener: viewUiListener,
            statusProvider: statusProvider
        )
        try instance.deserializeView(parent: parent, viewCreationParams: viewCreationParams)
        return instance
    }

    public func dispose() {
        barcodeCountListener.reset()
        viewListener.clearCache()
        view.delegate = nil
        view.uiDelegate = nil
        mode.removeListener(barcodeCountListener)
        mode.reset()
        DispatchQueue.main.async { [weak self] in
            self?.view.removeFromSuperview()
        }
    }
}

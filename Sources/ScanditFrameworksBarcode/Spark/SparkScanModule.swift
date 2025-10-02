/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture
import ScanditFrameworksCore

public enum SparkScanError: Error {
    case nilContext
    case json(String, String)
    case nilView
    case nilParent
}

open class SparkScanModule: NSObject, FrameworkModule {
    private let captureContext = DefaultFrameworksCaptureContext.shared
    private let emitter: Emitter
    
    private let viewCache = FrameworksViewsCache<FrameworksSparkScanView>()

    public init(emitter: Emitter) {
        self.emitter = emitter
    }

    public func didStart() {
        DeserializationLifeCycleDispatcher.shared.attach(observer: self)
    }

    public func didStop() {
        DeserializationLifeCycleDispatcher.shared.detach(observer: self)
    }

    public let defaults: DefaultsEncodable = dispatchMainSync { SparkScanDefaults.shared }

    public func addSparkScanListener(viewId: Int) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else { return }
        viewInstance.enableSparkScanListener()
    }

    public func removeSparkScanListener(viewId: Int) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else { return }
        viewInstance.disableSparkScanListener()
    }

    public func finishDidUpdateSession(viewId: Int, enabled: Bool) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else { return }
        viewInstance.finishDidUpdateCallback(enabled: enabled)
    }

    public func finishDidScan(viewId: Int, enabled: Bool) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else { return }
        viewInstance.finishDidScanCallback(enabled: enabled)
    }

    public func resetSession(viewId: Int) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else { return }
        viewInstance.resetLastSession()
    }

    public func addSparkScanViewUiListener(viewId: Int) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else { return }
        viewInstance.addSparkScanViewUiListener()
    }

    public func removeSparkScanViewUiListener(viewId: Int) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else { return }
        viewInstance.removeSparkScanViewUiListener()
    }

    public func addViewToContainer(_ container: UIView, jsonString: String, result: FrameworksResult) -> Int {
        guard let context = self.captureContext.context else {
            Log.error(SparkScanError.nilContext)
            result.reject(error: SparkScanError.nilContext)
            return -1
        }
        return dispatchMainSync {
            do {
                let viewCreationParams = SparkScanViewCreationData.fromJson(jsonString)

                if let existingView = viewCache.getView(viewId: viewCreationParams.viewId) {
                    existingView.dispose()
                    _ = viewCache.remove(viewId: existingView.viewId)
                }
                
                if let previousView = viewCache.getTopMost() {
                    previousView.hide()
                }
                
                let view = try FrameworksSparkScanView.create(
                    emitter: emitter,
                    context: context,
                    container: container,
                    viewCreationParams: viewCreationParams
                )
                viewCache.addView(view: view)
                result.success()
                return view.viewId
            } catch {
                Log.error(error)
                result.reject(error: error)
                return -1
            }
        }
    }

    public func updateView(viewId: Int, viewJson: String, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        viewInstance.updateView(viewJson: viewJson)
        result.success()
    }

    public func updateMode(viewId: Int, modeJson: String, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        do {
            try viewInstance.updateMode(modeJson: modeJson)
            result.success()
        } catch {
            Log.error(error)
            result.reject(error: error)
        }
    }

    public func pauseScanning(viewId: Int) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else { return }
        viewInstance.pauseScanning()
    }
    
    public func stopScanning(viewId: Int) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else { return }
        viewInstance.stopScanning()
    }

    public func startScanning(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            Log.error(SparkScanError.nilView)
            result.reject(error: SparkScanError.nilView)
            return
        }
        viewInstance.startScanning()
        result.success()
    }

    public func prepareScanning(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            Log.error(SparkScanError.nilView)
            result.reject(error: SparkScanError.nilView)
            return
        }
        viewInstance.prepareScanning()
        result.success()
    }

    public func showToast(viewId: Int, text: String, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            Log.error(SparkScanError.nilView)
            result.reject(error: SparkScanError.nilView)
            return
        }
        viewInstance.showToast(text: text)
        result.success()
    }

    public func setModeEnabled(viewId: Int, enabled: Bool) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else { return }
        viewInstance.setModeEnabled(enabled)
    }

    public func isModeEnabled() -> Bool {
        return viewCache.getTopMost()?.isModeEnabled() ?? false
    }

    public func submitFeedbackForBarcode(viewId: Int, feedbackJson: String?, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            Log.error(SparkScanError.nilView)
            result.reject(error: SparkScanError.nilView)
            return
        }
        viewInstance.submitFeedback(feedbackJson: feedbackJson)
        result.success()
    }
    
    public func addFeedbackDelegate(_ viewId: Int) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            return
        }
        viewInstance.addFeedbackDelegate()
    }

    public func removeFeedbackDelegate(_ viewId: Int) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            return
        }
        viewInstance.removeFeedbackDelegate()
    }

    public func bringSparkScanViewToFront(viewId: Int) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else { return }
        viewInstance.bringViewToTop()
    }
    
    public func setupViewConstraints(viewId: Int, referenceView: UIView) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else { return }
        viewInstance.setupViewConstraints(referenceView: referenceView)
    }
    
    public func hitTest(viewId: Int, point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let viewInstance = viewCache.getView(viewId: viewId) else { return nil }
        return viewInstance.hitTest(point, with: event)
    }

    public func disposeView(viewId: Int) {
        guard let viewInstance = viewCache.remove(viewId: viewId) else { return }
        viewInstance.dispose()
        
        if let previousView = viewCache.getTopMost() {
            previousView.show()
        }
    }
    
    public func getLastFrameDataBytes(frameId: String, result: FrameworksResult) {
        LastFrameData.shared.getLastFrameDataBytes(frameId: frameId) {
            result.success(result: $0)
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
}

extension SparkScanModule: DeserializationLifeCycleObserver {
    public func didDisposeDataCaptureContext() {
        viewCache.disposeAll()
    }
}

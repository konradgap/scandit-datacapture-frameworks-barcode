/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture
import ScanditFrameworksCore

open class BarcodePickModule: NSObject, FrameworkModule, DeserializationLifeCycleObserver {
    let emitter: Emitter

    private let captureContext = DefaultFrameworksCaptureContext.shared

    private let viewCache = FrameworksViewsCache<FrameworksBarcodePickView>()

    public init(emitter: Emitter) {
        self.emitter = emitter
    }

    public func didStart() {
        DeserializationLifeCycleDispatcher.shared.attach(observer: self)
    }

    public func didStop() {
        DeserializationLifeCycleDispatcher.shared.detach(observer: self)
        cleanup()
    }

    public func didDisposeDataCaptureContext() {
        cleanup()
    }

    private func cleanup() {
        viewCache.disposeAll()
    }

    public let defaults: DefaultsEncodable = BarcodePickDefaults.shared

    public func addViewToContainer(container: UIView, jsonString: String, result: FrameworksResult) {
        let block = { [weak self] in
            guard let self = self else {
                result.reject(error: ScanditFrameworksCoreError.nilSelf)
                return
            }
            guard let context = self.captureContext.context else {
                result.reject(error: ScanditFrameworksCoreError.nilDataCaptureContext)
                return
            }
            let json = JSONValue(string: jsonString)
            guard json.containsKey("View") else {
                result.reject(error: ScanditFrameworksCoreError.deserializationError(error: nil,
                                                                                     json: jsonString))
                return
            }

            do {
                let viewCreationParams = try BarcodePickViewCreationData.fromJson(jsonString)

                if let existingView = viewCache.getView(viewId: viewCreationParams.viewId) {
                    existingView.dispose()
                    _ = viewCache.remove(viewId: existingView.viewId)
                }

                if let previousView = viewCache.getTopMost() {
                    previousView.hide()
                }

                let frameworksView = try FrameworksBarcodePickView.create(
                    emitter: self.emitter,
                    parent: container,
                    context: context,
                    viewCreationParams: viewCreationParams
                )

                viewCache.addView(view: frameworksView)

                result.success(result: nil)
            } catch let error {
                result.reject(error: ScanditFrameworksCoreError.deserializationError(error: error,
                                                                                     json: nil))
                return
            }
        }
        dispatchMain(block)
    }
}

public extension BarcodePickModule {

    func viewStart(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        viewInstance.startMode()
        result.success()
    }

    func viewStop(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        viewInstance.stopMode()
        result.success()
    }

    func viewFreeze(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        DispatchQueue.main.async {
            viewInstance.view.freeze()
        }
        result.success()
    }


    func removeView(viewId: Int, result: FrameworksResult) {
        viewCache.remove(viewId: viewId)?.dispose()
        if let previousView = viewCache.getTopMost() {
            previousView.show()
        }
        result.success()
    }

    func updateView(viewId: Int, viewJson: String, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        viewInstance.updateView(viewJson: viewJson)
        result.success()
    }

    func finishProductIdentifierForItems(viewId: Int, barcodePickProductProviderCallbackItemsJson: String, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        viewInstance.finishProductIdentifierForItems(barcodePickProductProviderCallbackItemsJson: barcodePickProductProviderCallbackItemsJson)
        result.success()
    }

    func finishPickAction(viewId: Int, data: String, actionResult: Bool, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        viewInstance.finishPickAction(data: data, result: actionResult)
        result.success()
    }

    func addActionListener(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        viewInstance.addBarcodePickActionListener()
        result.success()
    }

    func removeActionListener(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        viewInstance.removeBarcodePickActionListener()
        result.success()
    }

    func addScanningListener(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        viewInstance.addBarcodePickScanningListener()
        result.success()
    }

    func removeScanningListener(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        viewInstance.removeBarcodePickScanningListener()
        result.success()
    }

    func addViewListener(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        viewInstance.addBarcodePickViewListener()
        result.success()
    }

    func removeViewListener(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        viewInstance.removeBarcodePickViewListener()
        result.success()
    }

    func addViewUiListener(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        viewInstance.addBarcodePickViewUiListener()
        result.success()
    }

    func removeViewUiListener(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        viewInstance.removeBarcodePickViewUiListener()
        result.success()
    }

    func addBarcodePickListener(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        viewInstance.addBarcodePickListener()
        result.success()
    }

    func removeBarcodePickListener(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        viewInstance.removeBarcodePickListener()
        result.success()
    }

    func viewReset(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        DispatchQueue.main.async {
            viewInstance.view.reset()
        }
        result.success()
    }

    func viewPause(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        DispatchQueue.main.async {
            viewInstance.view.pause()
        }
        result.success()
    }
    
    func viewResume(viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        DispatchQueue.main.async {
            viewInstance.view.start()
        }
        result.success()
    }

    func finishBarcodePickViewHighlightStyleCustomViewProviderViewForRequest(viewId: Int, response: [String: Any?], result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }

        guard let requestId = response["requestId"] as? Int else {
            result.success()
            return
        }

        var statusIconStyle: BarcodePickStatusIconStyle?

        let responseDict = response["response"] as? [String: Any]

        if let statusIconStyleJson = responseDict?["statusIconStyle"] as? String {
            statusIconStyle = BarcodePickStatusIconStyle(jsonString: statusIconStyleJson)
        }

        dispatchMain {
            var customView: UIImageView?
            if let viewBytes = responseDict?["view"] as? Data {
                customView = UIImageView()
                if let image = UIImage(data: viewBytes) {
                    customView?.image = image
                }
            }

            viewInstance.finishBarcodePickViewHighlightStyleCustomViewProviderViewForRequest(
                requestId: requestId,
                customView: customView,
                statusIconStyle: statusIconStyle
            )
            result.success()
        }
    }

    func finishBarcodePickViewHighlightStyleAsyncProviderStyleForRequest(viewId: Int, response: [String: Any?], result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }

        guard let requestId = response["requestId"] as? Int else {
            result.success()
            return
        }

        let responseJson = response["response"] as? String

        dispatchMain {
            viewInstance.finishBarcodePickViewHighlightStyleAsyncProviderStyleForRequest(
                requestId: requestId,
                responseJson: responseJson
            )
            result.success()
        }
    }

    func getTopMostView() -> BarcodePickView? {
        return viewCache.getTopMost()?.view
    }
}

/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditFrameworksCore
import ScanditBarcodeCapture

open class BarcodeFindModule: NSObject, FrameworkModule {
    private let emitter: Emitter
    private let captureContext = DefaultFrameworksCaptureContext.shared

    public init(emitter: Emitter) {
        self.emitter = emitter
        super.init()
    }

    private let viewCache = FrameworksViewsCache<FrameworksBarcodeFindView>()

    private var barcodeFindFeedback: BarcodeFindFeedback?

    public func didStart() {
        DeserializationLifeCycleDispatcher.shared.attach(observer: self)
    }

    public func didStop() {
        viewCache.disposeAll()
        DeserializationLifeCycleDispatcher.shared.detach(observer: self)
    }

    public let defaults: DefaultsEncodable = BarcodeFindDefaults.shared

    public func addViewToContainer(container: UIView, jsonString: String, result: FrameworksResult) {
        guard let context = self.captureContext.context else {
            result.reject(error: ScanditFrameworksCoreError.nilDataCaptureContext)
            return
        }
        
        do {
            
            let viewCreationParams = try BarcodeFindViewCreationData.fromJson(viewJson: jsonString)
            if let existingView = viewCache.getView(viewId: viewCreationParams.viewId) {
                existingView.dispose()
                _ = viewCache.remove(viewId: existingView.viewId)
            }

            if let previousView = viewCache.getTopMost() {
                previousView.hide()
            }
            
            let block = { [weak self] in
                guard let self = self else {
                    result.reject(error: ScanditFrameworksCoreError.nilSelf)
                    return
                }
                
                do {
                    let view = try FrameworksBarcodeFindView.create(
                        emitter: emitter,
                        context: context,
                        container: container,
                        viewCreationParams: viewCreationParams
                    )
                    viewCache.addView(view: view)
                    result.success()
                } catch {
                    result.reject(error: error)
                    return
                }
            }
            
            dispatchMain(block)
        } catch {
            result.reject(error: error)
            return
        }
    }
    
    public func getViewById(_ viewId: Int) -> BarcodeFindView? {
        return viewCache.getView(viewId: viewId)?.view
    }

    public func updateBarcodeFindView(_ viewId: Int, viewJson: String, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        viewInstance.updateBarcodeFindView(viewJson: viewJson)
        result.success()
    }

    public func onViewRemovedFromSuperview(viewId: Int) {
        if let viewInstance = viewCache.remove(viewId: viewId)  {
            viewInstance.dispose()
        }

        if let previousView = viewCache.getTopMost() {
            previousView.show()
        }
    }

    public func removeBarcodeFindView(_ viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.remove(viewId: viewId) else {
            return
        }

        viewInstance.dispose()
        result.success()
    }

    public func updateBarcodeFindMode(_ viewId: Int, modeJson: String, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }

        viewInstance.updateBarcodeFindMode(modeJson: modeJson)
        result.success()
    }

    public func addBarcodeFindListener(_ viewId:Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        viewInstance.addBarcodeFindListener()
        result.success()
    }

    public func removeBarcodeFindListener(_ viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        viewInstance.removeBarcodeFindListener()
        result.success()
    }

    public func addBarcodeFindViewListener(_ viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        viewInstance.addBarcodeFindViewListener()
        result.success()
    }

    public func removeBarcodeFindViewListener(_ viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        viewInstance.removeBarcodeFindViewListener()
        result.success()
    }

    public func setItemList(_ viewId: Int, barcodeFindItemsJson: String, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        viewInstance.setItemList(barcodeFindItemsJson: barcodeFindItemsJson)
        result.success()
    }

    public func prepareSearching(_ viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        viewInstance.viewPrepareSearching()
        result.success()
    }

    public func pauseSearching(_ viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }

        viewInstance.viewPauseSearching()
        result.success()
    }

    public func stopSearching(_ viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }

        viewInstance.viewStopSearching()
        result.success()
    }

    public func startSearching(_ viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        viewInstance.viewStartSearching()
        result.success()
    }

    public func startMode(_ viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }

        viewInstance.modeStart()
        result.success()
    }

    public func stopMode(_ viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }

        viewInstance.modeStop()
        result.success()
    }

    public func pauseMode(_ viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }

        viewInstance.modePause()
        result.success()
    }

    public func setModeEnabled(_ viewId: Int, enabled: Bool) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            return
        }

        viewInstance.setModeEnabled(enabled: enabled)
    }

    public func isModeEnabled() -> Bool {
        return viewCache.getTopMost()?.isModeEnabled() ?? false
    }

    public func setBarcodeFindTransformer(_ viewId: Int, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }

        viewInstance.setBarcodeFindTransformer()
        result.success()
    }
    
    public func removeBarcodeFindTransformer(_ viewId: Int, result: FrameworksResult) {
        // The native API isn't allowing the removal of the transformer
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        viewInstance.unsetBarcodeFindTransformer()
        result.success()
    }

    public func submitBarcodeFindTransformerResult(_ viewId: Int, transformedData: String?, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }

        viewInstance.submitBarcodeFindTransformerResult(transformedData: transformedData)
        result.success()
    }

    public func updateFeedback(_ viewId: Int, feedbackJson: String, result: FrameworksResult) {
        guard let viewInstance = viewCache.getView(viewId: viewId) else {
            result.success()
            return
        }
        do {
            try viewInstance.updateFeedback(feedbackJson: feedbackJson)
            result.success()
        } catch let error {
            result.reject(error: error)
        }
    }

    public func execute(method: FrameworksMethodCall, result: FrameworksResult) -> Bool {
        switch method.method {
        case "getBarcodeFindDefaults":
            result.success(result: defaults.stringValue)

        case "updateFindView":
            if let viewId: Int = method.argument(key: "viewId"),
               let barcodeFindViewJson: String = method.argument(key: "barcodeFindViewJson") {
                updateBarcodeFindView(viewId, viewJson: barcodeFindViewJson, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid viewId or barcodeFindViewJson argument", details: nil)
            }

        case "updateFindMode":
            if let viewId: Int = method.argument(key: "viewId"),
               let barcodeFindJson: String = method.argument(key: "barcodeFindJson") {
                updateBarcodeFindMode(viewId, modeJson: barcodeFindJson, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid viewId or barcodeFindJson argument", details: nil)
            }

        case "registerBarcodeFindListener":
            if let viewId: Int = method.argument(key: "viewId") {
                addBarcodeFindListener(viewId, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid viewId argument", details: nil)
            }

        case "unregisterBarcodeFindListener":
            if let viewId: Int = method.argument(key: "viewId") {
                removeBarcodeFindListener(viewId, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid viewId argument", details: nil)
            }

        case "registerBarcodeFindViewListener":
            if let viewId: Int = method.argument(key: "viewId") {
                addBarcodeFindViewListener(viewId, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid viewId argument", details: nil)
            }

        case "unregisterBarcodeFindViewListener":
            if let viewId: Int = method.argument(key: "viewId") {
                removeBarcodeFindViewListener(viewId, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid viewId argument", details: nil)
            }

        case "barcodeFindSetItemList":
            if let viewId: Int = method.argument(key: "viewId"),
               let itemsJson: String = method.argument(key: "itemsJson") {
                setItemList(viewId, barcodeFindItemsJson: itemsJson, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid viewId or itemsJson argument", details: nil)
            }

        case "barcodeFindViewStopSearching":
            if let viewId: Int = method.argument(key: "viewId") {
                stopSearching(viewId, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid viewId argument", details: nil)
            }

        case "barcodeFindViewStartSearching":
            if let viewId: Int = method.argument(key: "viewId") {
                startSearching(viewId, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid viewId argument", details: nil)
            }

        case "barcodeFindViewPauseSearching":
            if let viewId: Int = method.argument(key: "viewId") {
                pauseSearching(viewId, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid viewId argument", details: nil)
            }

        case "barcodeFindModeStart":
            if let viewId: Int = method.argument(key: "viewId") {
                startMode(viewId, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid viewId argument", details: nil)
            }

        case "barcodeFindModePause":
            if let viewId: Int = method.argument(key: "viewId") {
                pauseMode(viewId, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid viewId argument", details: nil)
            }

        case "barcodeFindModeStop":
            if let viewId: Int = method.argument(key: "viewId") {
                stopMode(viewId, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid viewId argument", details: nil)
            }

        case "setModeEnabledState":
            if let viewId: Int = method.argument(key: "viewId"),
               let enabled: Bool = method.argument(key: "enabled") {
                setModeEnabled(viewId, enabled: enabled)
                result.success()
            } else {
                result.reject(code: "-1", message: "Invalid viewId or enabled argument", details: nil)
            }

        case "setBarcodeTransformer":
            if let viewId: Int = method.argument(key: "viewId") {
                setBarcodeFindTransformer(viewId, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid viewId argument", details: nil)
            }

        case "submitBarcodeTransformerResult":
            if let viewId: Int = method.argument(key: "viewId"),
               let transformedBarcode: String? = method.argument(key: "transformedBarcode") {
                submitBarcodeFindTransformerResult(viewId, transformedData: transformedBarcode, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid viewId or transformedBarcode argument", details: nil)
            }

        case "updateFeedback":
            if let viewId: Int = method.argument(key: "viewId"),
               let feedbackJson: String = method.argument(key: "feedbackJson") {
                updateFeedback(viewId, feedbackJson: feedbackJson, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid viewId or feedbackJson argument", details: nil)
            }

        default:
            return false
        }

        return true
    }
}

extension BarcodeFindModule: DeserializationLifeCycleObserver {
    public func didDisposeDataCaptureContext() {
        viewCache.disposeAll()
    }
}

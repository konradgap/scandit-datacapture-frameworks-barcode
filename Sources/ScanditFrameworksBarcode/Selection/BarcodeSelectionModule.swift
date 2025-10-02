/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture
import ScanditFrameworksCore

public enum BarcodeSelectionError: Error {
    case modeDoesNotExist
    case nilOverlay
}

open class BarcodeSelectionModule: BasicFrameworkModule<FrameworksBarcodeSelectionMode> {
    private let emitter: Emitter
    private var aimedBrushProviderFlag: Bool = false
    private var trackedBrushProviderFlag: Bool = false
    private let aimedBrushProvider: FrameworksBarcodeSelectionAimedBrushProvider
    private let trackedBrushProvider: FrameworksBarcodeSelectionTrackedBrushProvider
    private let barcodeSelectionDeserializer: BarcodeSelectionDeserializer
    private let captureContext = DefaultFrameworksCaptureContext.shared
    private let captureViewHandler = DataCaptureViewHandler.shared
    
    public init(emitter: Emitter,
                aimedBrushProvider: FrameworksBarcodeSelectionAimedBrushProvider,
                trackedBrushProvider: FrameworksBarcodeSelectionTrackedBrushProvider,
                barcodeSelectionDeserializer: BarcodeSelectionDeserializer = BarcodeSelectionDeserializer()) {
        self.emitter = emitter
        self.aimedBrushProvider = aimedBrushProvider
        self.trackedBrushProvider = trackedBrushProvider
        self.barcodeSelectionDeserializer = barcodeSelectionDeserializer
    }
    
    public override func didStart() {
        Deserializers.Factory.add(barcodeSelectionDeserializer)
        DeserializationLifeCycleDispatcher.shared.attach(observer: self)
    }
    
    public override func didStop() {
        Deserializers.Factory.remove(barcodeSelectionDeserializer)
        DeserializationLifeCycleDispatcher.shared.detach(observer: self)
        removeAimedBarcodeBrushProvider()
        removeTrackedBarcodeBrushProvider()
        self.dataCaptureContextAllModeRemoved()
    }
    
    // MARK: - Module API
    
    public let defaults: DefaultsEncodable = BarcodeSelectionDefaults.shared
    
    public func addListener(modeId: Int) {
        getModeFromCache(modeId)?.addListener()
    }
    
    public func removeListener(modeId: Int) {
        getModeFromCache(modeId)?.removeListener()
    }
    
    public func unfreezeCamera(modeId: Int) {
        getModeFromCache(modeId)?.unfreezeCamera()
    }
    
    public func resetSelection(modeId: Int) {
        getModeFromCache(modeId)?.resetSelection()
    }
    
    public func submitBarcodeCountForIdentifier(modeId: Int, selectionIdentifier: String, result: FrameworksResult) {
        guard let mode = getModeFromCache(modeId) else {
            result.reject(error: BarcodeSelectionError.modeDoesNotExist)
            return
        }
        let count = mode.getSelectedBarcodeCount(selectionIdentifier: selectionIdentifier)
        result.success(result: count)
    }
    
    public func resetLatestSession(modeId: Int, frameSequenceId: Int?) {
        getModeFromCache(modeId)?.resetSession(frameSequenceId: frameSequenceId)
    }
    
    public func finishDidSelect(modeId: Int, enabled: Bool) {
        getModeFromCache(modeId)?.finishDidSelect(enabled: enabled)
    }
    
    public func finishDidUpdate(modeId: Int, enabled: Bool) {
        getModeFromCache(modeId)?.finishDidUpdateSession(enabled: enabled)
    }
    
    public func increaseCountForBarcodes(modeId: Int, barcodesJson: String, result: FrameworksResult) {
        guard let selection = getModeFromCache(modeId) else {
            result.reject(error: BarcodeSelectionError.modeDoesNotExist)
            return
        }
        selection.increaseCountForBarcodesFromJsonString(barcodesJson: barcodesJson)
        result.success(result: nil)
    }
    
    public func setAimedBrushProvider(result: FrameworksResult) {
        aimedBrushProviderFlag = true
        result.success(result: nil)
    }
    
    public func removeAimedBarcodeBrushProvider() {
        aimedBrushProviderFlag = false
        aimedBrushProvider.clearCache()
        if let overlay: BarcodeSelectionBasicOverlay = captureViewHandler.findFirstOverlayOfType() {
            overlay.setAimedBarcodeBrushProvider(nil)
        }
    }
    
    public func finishBrushForAimedBarcode(brushJson: String?, selectionIdentifier: String?) {
        aimedBrushProvider.finishCallback(brushJson: brushJson, selectionIdentifier: selectionIdentifier)
    }
    
    public func finishBrushForTrackedBarcode(brushJson: String?, selectionIdentifier: String?) {
        trackedBrushProvider.finishCallback(brushJson: brushJson, selectionIdentifier: selectionIdentifier)
    }
    
    public func setTextForAimToSelectAutoHint(text:String, result: FrameworksResult) {
        guard let overlay: BarcodeSelectionBasicOverlay = captureViewHandler.findFirstOverlayOfType()  else {
            result.reject(error: BarcodeSelectionError.nilOverlay)
            return
        }
        overlay.setTextForAimToSelectAutoHint(text)
        result.success(result: nil)
    }
    
    public func setTrackedBrushProvider(result: FrameworksResult) {
        trackedBrushProviderFlag = true
        result.success(result: nil)
    }
    
    public func removeTrackedBarcodeBrushProvider() {
        trackedBrushProviderFlag = false
        trackedBrushProvider.clearCache()
        if let overlay: BarcodeSelectionBasicOverlay = captureViewHandler.findFirstOverlayOfType() {
            overlay.setTrackedBarcodeBrushProvider(nil)
        }
    }
    
    public func selectAimedBarcode(modeId: Int) {
        getModeFromCache(modeId)?.selectAimedBarcode()
    }
    
    public func unselectBarcodes(modeId: Int, barcodesJson: String, result: FrameworksResult) {
        guard let mode = getModeFromCache(modeId) else {
            result.reject(error: BarcodeSelectionError.modeDoesNotExist)
            return
        }
        mode.unselectBarcodesFromJsonString(barcodesJson: barcodesJson)
        result.success(result: nil)
    }
    
    public func setSelectBarcodeEnabled(modeId: Int, barcodesJson: String, enabled: Bool, result: FrameworksResult) {
        guard let mode = getModeFromCache(modeId) else {
            result.reject(error: BarcodeSelectionError.modeDoesNotExist)
            return
        }
        mode.setSelectBarcodeEnabledFromJsonString(barcodesJson: barcodesJson, enabled: enabled)
        result.success(result: nil)
    }
    
    public func setModeEnabled(modeId: Int, enabled: Bool) {
        getModeFromCache(modeId)?.isEnabled = enabled
    }
    
    public func isTopmostModeEnabled() -> Bool {
        return getTopmostMode()?.isEnabled == true
    }
    
    public func setTopmostModeEnabled(enabled: Bool) {
        getTopmostMode()?.isEnabled = enabled
    }
    
    public func updateModeFromJson(modeId: Int, modeJson: String, result: FrameworksResult) {
        guard let mode = getModeFromCache(modeId) else {
            result.success(result: nil)
            return
        }
        do {
            try mode.updateModeFromJson(modeJson: modeJson)
            result.success(result: nil)
        } catch {
            result.reject(error: error)
        }
    }
    
    public func applyModeSettings(modeId: Int, modeSettingsJson: String, result: FrameworksResult) {
        guard let mode = getModeFromCache(modeId) else {
            result.success(result: nil)
            return
        }
        do {
            try mode.applySettings(modeSettingsJson: modeSettingsJson)
            result.success(result: nil)
        } catch {
            result.reject(error: error)
        }
    }
    
    public func updateFeedback(modeId: Int, feedbackJson: String, result: FrameworksResult) {
        guard let mode = getModeFromCache(modeId) else {
            result.success(result: nil)
            return
        }
        
        do {
            mode.updateFeedback(feedback: try BarcodeSelectionFeedback(fromJSONString: feedbackJson))
            result.success(result: nil)
        } catch {
            result.reject(error: error)
        }
    }
    
    public func updateBasicOverlay(overlayJson: String, result: FrameworksResult) {
        let block = { [weak self] in
            guard let self = self else {
                result.reject(error: ScanditFrameworksCoreError.nilSelf)
                return
            }
            guard let overlay: BarcodeSelectionBasicOverlay = self.captureViewHandler.findFirstOverlayOfType() else {
                result.success(result: nil)
                return
            }
            
            do {
                try self.barcodeSelectionDeserializer.update(overlay, fromJSONString: overlayJson)
                result.success(result: nil)
            } catch {
                result.reject(error: error)
            }
        }
        dispatchMain(block)
    }
    
    public func getLastFrameDataBytes(frameId: String, result: FrameworksResult) {
        LastFrameData.shared.getLastFrameDataBytes(frameId: frameId) {
            result.success(result: $0)
        }
    }
    
    // MARK: - Execute Method
    public func execute(method: FrameworksMethodCall, result: FrameworksResult) -> Bool {
        switch method.method {
        case "getBarcodeSelectionDefaults":
            let jsonString = defaults.stringValue
            result.success(result: jsonString)
            
        case "getBarcodeSelectionSessionCount":
            if let selectionIdentifier: String = method.argument(key: "selectionIdentifier"),
               let modeId: Int = method.argument(key: "modeId") {
                submitBarcodeCountForIdentifier(modeId: modeId, selectionIdentifier: selectionIdentifier, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid selectionIdentifier argument", details: nil)
            }
            
        case "resetBarcodeSelectionSession":
            guard let modeId: Int = method.argument(key: "modeId") else {
                result.reject(code: "-1", message: "Invalid modeId argument", details: nil)
                return true
            }
            resetLatestSession(modeId: modeId, frameSequenceId: method.argument(key: "frameSequenceId"))
            result.success(result: nil)
            
        case "addBarcodeSelectionListener":
            guard let modeId: Int = method.argument(key: "modeId") else {
                result.reject(code: "-1", message: "Invalid modeId argument", details: nil)
                return true
            }
            addListener(modeId: modeId)
            result.success(result: nil)
            
        case "removeBarcodeSelectionListener":
            guard let modeId: Int = method.argument(key: "modeId") else {
                result.reject(code: "-1", message: "Invalid modeId argument", details: nil)
                return true
            }
            removeListener(modeId: modeId)
            result.success(result: nil)
            
        case "resetMode":
            guard let modeId: Int = method.argument(key: "modeId") else {
                result.reject(code: "-1", message: "Invalid modeId argument", details: nil)
                return true
            }
            resetSelection(modeId: modeId)
            result.success(result: nil)
            
        case "unfreezeCamera":
            guard let modeId: Int = method.argument(key: "modeId") else {
                result.reject(code: "-1", message: "Invalid modeId argument", details: nil)
                return true
            }
            unfreezeCamera(modeId: modeId)
            result.success(result: nil)
            
        case "finishDidUpdateSelection":
            guard let modeId: Int = method.argument(key: "modeId") else {
                result.reject(code: "-1", message: "Invalid modeId argument", details: nil)
                return true
            }
            let enabled: Bool = method.argument(key: "enabled") ?? false
            finishDidSelect(modeId: modeId, enabled: enabled)
            result.success(result: nil)
            
        case "finishDidUpdateSession":
            guard let modeId: Int = method.argument(key: "modeId") else {
                result.reject(code: "-1", message: "Invalid modeId argument", details: nil)
                return true
            }
            let enabled: Bool = method.argument(key: "enabled") ?? false
            finishDidUpdate(modeId: modeId, enabled: enabled)
            result.success(result: nil)
            
        case "getLastFrameData":
            if let frameId: String = method.arguments() {
                getLastFrameDataBytes(frameId: frameId, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid frameId argument", details: nil)
            }
            
        case "setModeEnabledState":
            guard let modeId: Int = method.argument(key: "modeId") else {
                result.reject(code: "-1", message: "Invalid modeId argument", details: nil)
                return true
            }
            let enabled: Bool = method.argument(key: "enabled") ?? false
            setModeEnabled(modeId: modeId, enabled: enabled)
            result.success(result: nil)
            
        case "updateBarcodeSelectionMode":
            guard let modeId: Int = method.argument(key: "modeId") else {
                result.reject(code: "-1", message: "Invalid modeId argument", details: nil)
                return true
            }
            if let modeJson: String = method.argument(key: "modeJson") {
                updateModeFromJson(modeId: modeId, modeJson: modeJson, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid mode JSON argument", details: nil)
            }
            
        case "applyBarcodeSelectionModeSettings":
            guard let modeId: Int = method.argument(key: "modeId") else {
                result.reject(code: "-1", message: "Invalid modeId argument", details: nil)
                return true
            }
            if let modeSettingsJson: String = method.argument(key: "modeSettingsJson") {
                applyModeSettings(modeId: modeId, modeSettingsJson: modeSettingsJson, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid mode settings JSON argument", details: nil)
            }
            
        case "updateBarcodeSelectionBasicOverlay":
            if let overlayJson: String = method.arguments() {
                updateBasicOverlay(overlayJson: overlayJson, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid overlay JSON argument", details: nil)
            }
            
        case "updateFeedback":
            guard let modeId: Int = method.argument(key: "modeId") else {
                result.reject(code: "-1", message: "Invalid modeId argument", details: nil)
                return true
            }
            if let feedbackJson: String = method.argument(key: "feedbackJson") {
                updateFeedback(modeId: modeId, feedbackJson: feedbackJson, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid feedback JSON argument", details: nil)
            }
            
        default:
            return false
        }
        return true
    }
}

extension BarcodeSelectionModule: DeserializationLifeCycleObserver {
    public func dataCaptureContext(addMode modeJson: String) throws {
        let creationParams = BarcodeSelectionModeCreationData.fromJson(modeJson)
        if  creationParams.modeType != "barcodeSelection"  {
            return
        }
        guard let dcContext = self.captureContext.context else {
            Log.error("Unable to add the barcode selection mode to the context. DataCaptureContext is nil.")
            return
        }
        do {
            let selectionMode = try FrameworksBarcodeSelectionMode.create(
                emitter: emitter,
                captureContext: captureContext,
                creationData: creationParams,
                dataCaptureContext: dcContext,
                deserializer: barcodeSelectionDeserializer
            )
            
            addModeToCache(modeId: creationParams.modeId, mode: selectionMode)
            
            for action in getPostModeCreationActions(creationParams.modeId) {
                action()
            }
            let parentId = selectionMode.parentId ?? -1
            for action in getPostModeCreationActionsByParent(parentId) {
                action()
            }
        } catch {
            Log.error("Unable to add the barcode selection mode to the context.", error: error)
        }
    }
    
    public func dataCaptureContext(removeMode modeJson: String) {
        let json = JSONValue(string: modeJson)
        if  json.string(forKey: "type") != "barcodeSelection" {
            return
        }
        let modeId = json.integer(forKey: "modeId")
        
        guard let mode = self.removeModeFromCache(modeId) else {
            return
        }
        mode.dispose()
    }
    
    public func dataCaptureContextAllModeRemoved() {
        for mode in getAllModesInCache() {
            mode.dispose()
        }
        removeAllModesFromCache()
        clearPostModeCreationActions(nil)
    }
    
    public func didDisposeDataCaptureContext() {
        self.dataCaptureContextAllModeRemoved()
    }
    
    public func dataCaptureView(addOverlay overlayJson: String, to view: FrameworksDataCaptureView) throws {
        let creationParams = BarcodeSelectionOverlayCreationData.create(overlayJson: overlayJson)
        
        if  creationParams.isValidBasicOverlayType == false {
            return
        }
        
        let parentId = view.parentId ?? -1
        
        var mode: FrameworksBarcodeSelectionMode?
        
        if parentId != -1 {
            mode = getModeFromCacheByParent(parentId) as? FrameworksBarcodeSelectionMode
        } else {
            mode = getModeFromCache(creationParams.modeId)
        }
        
        guard let frameworksMode = mode else {
            if parentId != -1 {
                addPostModeCreationActionByParent(parentId) {
                    try? self.dataCaptureView(addOverlay: overlayJson, to: view)
                }
            } else {
                addPostModeCreationAction(creationParams.modeId) {
                    try? self.dataCaptureView(addOverlay: overlayJson, to: view)
                }
            }
            return
        }
        do {
            try dispatchMainSync {
                let overlay = try barcodeSelectionDeserializer.basicOverlay(fromJSONString: overlayJson, withMode: frameworksMode.mode)
                updateOverlayProps(overlay: overlay, creationParams: creationParams)
                view.addOverlay(overlay)
            }
        } catch {
            Log.error("Error adding the barcode selection basic overlay", error: error)
        }
    }
    
    private func updateOverlayProps(
        overlay: BarcodeSelectionBasicOverlay,
        creationParams: BarcodeSelectionOverlayCreationData
    ) {
        if (creationParams.hasAimedBrushProvider) {
            overlay.setAimedBarcodeBrushProvider(aimedBrushProvider)
        } else {
            overlay.setAimedBarcodeBrushProvider(nil)
        }
        if (creationParams.hasTrackedBrushProvider) {
            overlay.setTrackedBarcodeBrushProvider(trackedBrushProvider)
        } else {
            overlay.setTrackedBarcodeBrushProvider(nil)
        }
        if let textForSelectOrDoubleTapToFreezeHint = creationParams.textForSelectOrDoubleTapToFreezeHint {
            overlay.setTextForSelectOrDoubleTapToFreezeHint(textForSelectOrDoubleTapToFreezeHint)
        }
        if let textForTapToSelectHint = creationParams.textForTapToSelectHint {
            overlay.setTextForTapToSelectHint(textForTapToSelectHint)
        }
        if let textForDoubleTapToUnfreezeHint = creationParams.textForDoubleTapToUnfreezeHint {
            overlay.setTextForDoubleTapToUnfreezeHint(textForDoubleTapToUnfreezeHint)
        }
        if let textForTapAnywhereToSelectHint = creationParams.textForTapAnywhereToSelectHint {
            overlay.setTextForTapAnywhereToSelectHint(textForTapAnywhereToSelectHint)
        }
        if let textForAimToSelectAutoHint = creationParams.textForAimToSelectAutoHint {
            overlay.setTextForAimToSelectAutoHint(textForAimToSelectAutoHint)
        }
    }
}


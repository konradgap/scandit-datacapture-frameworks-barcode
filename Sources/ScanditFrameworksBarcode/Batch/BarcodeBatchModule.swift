/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture
import ScanditFrameworksCore

open class BarcodeBatchModule: BasicFrameworkModule<FrameworksBarcodeBatchMode> {
    private let barcodeBatchBasicOverlayListener: FrameworksBarcodeBatchBasicOverlayListener
    private let barcodeBatchAdvancedOverlayListener: FrameworksBarcodeBatchAdvancedOverlayListener
    private let barcodeBatchDeserializer: BarcodeBatchDeserializer
    private let emitter: Emitter
    private let didTapViewForTrackedBarcodeEvent = Event(.didTapViewForTrackedBarcode)
    private let captureContext = DefaultFrameworksCaptureContext.shared
    private let captureViewHandler = DataCaptureViewHandler.shared

    // Cached session
    private let cachedBatchSession: AtomicValue<FrameworksBarcodeBatchSession?> = AtomicValue(nil)

    public init(emitter: Emitter) {
        self.emitter = emitter
        self.barcodeBatchBasicOverlayListener = FrameworksBarcodeBatchBasicOverlayListener(emitter: emitter)
        self.barcodeBatchAdvancedOverlayListener = FrameworksBarcodeBatchAdvancedOverlayListener(emitter: emitter)
        self.barcodeBatchDeserializer = BarcodeBatchDeserializer()
    }

    private var advancedOverlayViewPool: AdvancedOverlayViewPool?

    // MARK: - FrameworkModule API

    public override func didStart() {
        DeserializationLifeCycleDispatcher.shared.attach(observer: self)
    }

    public override func didStop() {
        DeserializationLifeCycleDispatcher.shared.detach(observer: self)
    }

    // MARK: - Module API exposed to the platform native modules

    public let defaults: DefaultsEncodable = BarcodeBatchDefaults.shared

    public func addBarcodeBatchListener(_ modeId: Int) {
        guard let mode = getModeFromCache(modeId) else {
            addPostModeCreationAction(modeId, action: {
                self.addBarcodeBatchListener(modeId)
            })
            return
        }
        mode.addListener()
    }

    public func removeBarcodeBatchListener(_ modeId: Int) {
        if let mode = getModeFromCache(modeId) {
            mode.removeListener()
        }
    }

    public func finishDidUpdateSession(modeId: Int, enabled: Bool) {
        if let mode = getModeFromCache(modeId) {
            mode.finishDidUpdateSession(enabled: enabled)
        }
    }

    public func resetSession(frameSequenceId: Int?) {
        if let session = self.cachedBatchSession.value {
            session.batchSession?.reset()
        }
    }

    public func addBasicOverlayListener(_ dataCaptureViewId: Int) {
        if let dcView = self.captureViewHandler.getView(dataCaptureViewId),
           let overlay: BarcodeBatchBasicOverlay = dcView.findFirstOfType() {
            overlay.delegate = barcodeBatchBasicOverlayListener
        }
    }

    public func removeBasicOverlayListener(_ dataCaptureViewId: Int) {
        if let dcView = self.captureViewHandler.getView(dataCaptureViewId),
           let overlay: BarcodeBatchBasicOverlay = dcView.findFirstOfType() {
            overlay.delegate = nil
        }
    }

    public func clearBasicOverlayTrackedBarcodeBrushes(_ dataCaptureViewId: Int) {
        dispatchMain {
            if let dcView = self.captureViewHandler.getView(dataCaptureViewId),
               let overlay: BarcodeBatchBasicOverlay = dcView.findFirstOfType() {
                overlay.clearTrackedBarcodeBrushes()
            }
        }
    }

    public func setBasicOverlayBrush(_ dataCaptureViewId: Int, brushJson: String?, trackedBarcodeId: Int) {
        let brush = brushJson.flatMap { Brush(jsonString: $0) }
        if let trackedBarcode = trackedBarcode(by: trackedBarcodeId) {
            dispatchMain {
                if let dcView = self.captureViewHandler.getView(dataCaptureViewId),
                   let overlay: BarcodeBatchBasicOverlay = dcView.findFirstOfType() {
                    overlay.setBrush(brush, for: trackedBarcode)
                }
            }
        }
    }

    public func addAdvancedOverlayListener(_ dataCaptureViewId: Int) {
        dispatchMain {
            if let dcView = self.captureViewHandler.getView(dataCaptureViewId),
               let overlay: BarcodeBatchAdvancedOverlay = dcView.findFirstOfType() {
                overlay.delegate = self.barcodeBatchAdvancedOverlayListener
            }
            self.advancedOverlayViewPool = AdvancedOverlayViewPool(
                emitter: self.emitter,
                didTapViewForTrackedBarcodeEvent: self.didTapViewForTrackedBarcodeEvent
            )
        }
    }

    public func removeAdvancedOverlayListener(_ dataCaptureViewId: Int) {
        dispatchMain {
            if let dcView = self.captureViewHandler.getView(dataCaptureViewId),
               let overlay: BarcodeBatchAdvancedOverlay = dcView.findFirstOfType() {
                overlay.delegate = nil
            }
            self.advancedOverlayViewPool?.clear()
        }
    }

    public func clearAdvancedOverlayTrackedBarcodeViews(_ dataCaptureViewId: Int) {
        dispatchMain {
            if let dcView = self.captureViewHandler.getView(dataCaptureViewId),
               let overlay: BarcodeBatchAdvancedOverlay = dcView.findFirstOfType() {
                overlay.clearTrackedBarcodeViews()
            }
        }
    }

    public func setWidgetForTrackedBarcode(with viewParams: [String: Any?]) {
        let data = AdvancedOverlayViewData(dictionary: viewParams)
        
        guard let dcView = self.captureViewHandler.getView(data.dataCaptureViewId),
           let overlay: BarcodeBatchAdvancedOverlay = dcView.findFirstOfType() else {
            return
        }
        
        guard let barcode = trackedBarcode(by: data.trackedBarcodeId) else {
            return
        }
        guard let widgedData = data.widgetData else {
            advancedOverlayViewPool?.removeView(for: barcode)
            dispatchMain {
                
               overlay.setView(nil, for: barcode)
            }
            return
        }
        guard let view = advancedOverlayViewPool?.getOrCreateView(barcode: barcode, widgetData: widgedData) else { return }
        dispatchMain {
           overlay.setView(view, for: barcode)
        }
    }

    public func setViewForTrackedBarcode(view: TappableView?,
                                         trackedBarcodeId: Int,
                                         sessionFrameSequenceId: Int?,
                                         dataCaptureViewId: Int) {
        guard let dcView = self.captureViewHandler.getView(dataCaptureViewId),
           let overlay: BarcodeBatchAdvancedOverlay = dcView.findFirstOfType() else {
            return
        }
        guard let barcode = trackedBarcode(by: trackedBarcodeId) else {
            return
        }
        view?.didTap = { [weak self] in
            guard let self = self else { return }
            self.didTapViewForTrackedBarcodeEvent.emit(
                on: self.emitter,
                payload: ["trackedBarcode": barcode.jsonString]
            )
        }
        dispatchMain {
            overlay.setView(view, for: barcode)
        }
    }

    public func setAnchorForTrackedBarcode(anchorJson: String,
                                           trackedBarcodeId: Int,
                                           dataCaptureViewId: Int) {
        guard let dcView = self.captureViewHandler.getView(dataCaptureViewId),
           let overlay: BarcodeBatchAdvancedOverlay = dcView.findFirstOfType() else {
            return
        }
        guard let barcode = trackedBarcode(by: trackedBarcodeId) else {
            return
        }
        
        var anchor: Anchor = .center
        SDCAnchorFromJSONString(anchorJson, &anchor)

        dispatchMain {
            overlay.setAnchor(anchor, for: barcode)
        }
    }

    public func setOffsetForTrackedBarcode(offsetJson: String,
                                           trackedBarcodeId: Int,
                                           dataCaptureViewId: Int) {
        guard let dcView = self.captureViewHandler.getView(dataCaptureViewId),
           let overlay: BarcodeBatchAdvancedOverlay = dcView.findFirstOfType() else {
            return
        }
        
        guard let barcode = trackedBarcode(by: trackedBarcodeId) else {
            return
        }
        var offset: PointWithUnit = .zero
        SDCPointWithUnitFromJSONString(offsetJson, &offset)
        dispatchMain {
            overlay.setOffset(offset, for: barcode)
        }
    }

    public func trackedBarcode(by id: Int) -> TrackedBarcode? {
        guard let session = self.cachedBatchSession.value else {
            return nil
        }
        return session.trackedBarcodes[id]
    }

    public func setModeEnabled(_ modeId: Int, enabled: Bool) {
        getModeFromCache(modeId)?.isEnabled = enabled
    }

    public func isModeEnabled() -> Bool {
        return getTopmostMode()?.isEnabled == true
    }

    public func updateModeFromJson(modeJson: String, result: FrameworksResult) {
        let modeId = JSONValue(string: modeJson).integer(forKey: "modeId", default: -1)

        if modeId == -1 {
            result.reject(error: ScanditFrameworksCoreError.nilArgument)
            return
        }

        guard let mode = getModeFromCache(modeId) else {
            result.success()
            return
        }

        do {
            try mode.updateModeFromJson(modeJson: modeJson)
            result.success()
        } catch {
            result.reject(error: error)
        }
    }

    public func applyModeSettings(_ modeId: Int, modeSettingsJson: String, result: FrameworksResult) {
        guard let mode = getModeFromCache(modeId) else {
            result.success()
            return
        }
        do {
            try mode.applySettings(modeSettingsJson: modeSettingsJson)
            result.success()
        } catch {
            result.reject(error: error)
        }
    }

    public func updateBasicOverlay(_ dataCaptureViewId: Int, overlayJson: String, result: FrameworksResult) {
        let block = { [weak self] in
            guard let self = self else {
                result.reject(error: ScanditFrameworksCoreError.nilSelf)
                return
            }
            
            guard let dcView = self.captureViewHandler.getView(dataCaptureViewId),
               let overlay: BarcodeBatchBasicOverlay = dcView.findFirstOfType() else {
                result.success()
                return
            }

            do {
                try self.barcodeBatchDeserializer.update(overlay, fromJSONString: overlayJson)
                result.success()
            } catch {
                result.reject(error: error)
            }
        }
        dispatchMain(block)
    }

    public func updateAdvancedOverlay(_ dataCaptureViewId: Int, overlayJson: String, result: FrameworksResult) {
        let block = { [weak self] in
            guard let self = self else {
                result.reject(error: ScanditFrameworksCoreError.nilSelf)
                return
            }
            
            guard let dcView = self.captureViewHandler.getView(dataCaptureViewId),
               let overlay: BarcodeBatchAdvancedOverlay = dcView.findFirstOfType() else {
                result.success()
                return
            }

            do {
                try self.barcodeBatchDeserializer.update(overlay, fromJSONString: overlayJson)
                result.success()
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
        case "getBarcodeBatchDefaults":
            let defaultsDict = defaults.toEncodable()
            if let jsonString = defaultsDict.encodeToJSONString() {
                result.success(result: jsonString)
            } else {
                result.reject(code: "-1", message: "Failed to encode defaults to JSON", details: nil)
            }

        case "addBarcodeBatchListener":
            if let modeId: Int = method.argument(key: "modeId") {
                addBarcodeBatchListener(modeId)
                result.success()
            } else {
                result.reject(code: "-1", message: "Invalid modeId argument", details: nil)
            }

        case "removeBarcodeBatchListener":
            if let modeId: Int = method.argument(key: "modeId") {
                removeBarcodeBatchListener(modeId)
                result.success()
            } else {
                result.reject(code: "-1", message: "Invalid modeId argument", details: nil)
            }

        case "barcodeBatchFinishDidUpdateSession":
            if let enabled: Bool = method.argument(key: "enabled"), let modeId: Int = method.argument(key: "modeId") {
                finishDidUpdateSession(modeId: modeId, enabled: enabled)
                result.success(result: true)
            } else {
                result.reject(code: "-1", message: "Invalid enabled or modeId argument", details: nil)
            }

        case "resetBarcodeBatchSession":
            let frameSequenceId: Int? = method.arguments()
            resetSession(frameSequenceId: frameSequenceId)
            result.success()

        case "getLastFrameData":
            if let frameId: String = method.arguments() {
                getLastFrameDataBytes(frameId: frameId, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid frameId argument", details: nil)
            }

        case "addBarcodeBatchAdvancedOverlayDelegate":
            if let dataCaptureViewId: Int = method.argument(key: "dataCaptureViewId")  {
                addAdvancedOverlayListener(dataCaptureViewId)
                result.success()
            } else {
                result.reject(code: "-1", message: "Invalid dataCaptureViewId argument", details: nil)
            }

        case "removeBarcodeBatchAdvancedOverlayDelegate":
            if let dataCaptureViewId: Int = method.argument(key: "dataCaptureViewId")  {
                removeAdvancedOverlayListener(dataCaptureViewId)
                result.success()
            } else {
                result.reject(code: "-1", message: "Invalid dataCaptureViewId argument", details: nil)
            }

        case "clearTrackedBarcodeWidgets":
            if let dataCaptureViewId: Int = method.argument(key: "dataCaptureViewId")  {
                clearAdvancedOverlayTrackedBarcodeViews(dataCaptureViewId)
                result.success()
            } else {
                result.reject(code: "-1", message: "Invalid dataCaptureViewId argument", details: nil)
            }

        case "setWidgetForTrackedBarcode":
            if let args: [String: Any?] = method.arguments() {
                setWidgetForTrackedBarcode(with: args)
                result.success()
            } else {
                result.reject(code: "-1", message: "Invalid argument for setWidgetForTrackedBarcode", details: nil)
            }

        case "setAnchorForTrackedBarcode":
            if let dataCaptureViewId: Int = method.argument(key: "dataCaptureViewId"),
               let anchorJson: String = method.argument(key: "anchor"),
               let trackedBarcodeIdentifier: Int = method.argument(key: "trackedBarcodeIdentifier") {
                setAnchorForTrackedBarcode(anchorJson: anchorJson, trackedBarcodeId: trackedBarcodeIdentifier, dataCaptureViewId: dataCaptureViewId)
                
            } else {
                result.reject(code: "-1", message: "Invalid argument for setAnchorForTrackedBarcode", details: nil)
            }

        case "setOffsetForTrackedBarcode":
            if let dataCaptureViewId: Int = method.argument(key: "dataCaptureViewId"),
               let offsetJson: String = method.argument(key: "offsetJson"),
               let trackedBarcodeIdentifier: Int = method.argument(key: "trackedBarcodeIdentifier") {
                
                setOffsetForTrackedBarcode(offsetJson: offsetJson, trackedBarcodeId: trackedBarcodeIdentifier, dataCaptureViewId: dataCaptureViewId)
            } else {
                result.reject(code: "-1", message: "Invalid argument for setOffsetForTrackedBarcode", details: nil)
            }

        case "subscribeBarcodeBatchBasicOverlayListener":
            if let dataCaptureViewId: Int = method.argument(key: "dataCaptureViewId")  {
                addBasicOverlayListener(dataCaptureViewId)
                result.success()
            } else {
                result.reject(code: "-1", message: "Invalid dataCaptureViewId argument", details: nil)
            }

        case "unsubscribeBarcodeBatchBasicOverlayListener":
            if let dataCaptureViewId: Int = method.argument(key: "dataCaptureViewId")  {
                removeBasicOverlayListener(dataCaptureViewId)
                result.success()
            } else {
                result.reject(code: "-1", message: "Invalid dataCaptureViewId argument", details: nil)
            }

        case "setBrushForTrackedBarcode":
            if let dataCaptureViewId: Int = method.argument(key: "dataCaptureViewId"),
               let trackedBarcodeIdentifier: Int = method.argument(key: "trackedBarcodeIdentifier") {
                
                let brushJson: String? = method.argument(key: "brushJson")
                
                setBasicOverlayBrush(dataCaptureViewId, brushJson: brushJson, trackedBarcodeId: trackedBarcodeIdentifier)
                result.success()
            } else {
                result.reject(code: "-1", message: "Invalid brush JSON argument", details: nil)
            }

        case "clearTrackedBarcodeBrushes":
            if let dataCaptureViewId: Int = method.argument(key: "dataCaptureViewId")  {
                clearBasicOverlayTrackedBarcodeBrushes(dataCaptureViewId)
                result.success()
            } else {
                result.reject(code: "-1", message: "Invalid dataCaptureViewId argument", details: nil)
            }

        case "setModeEnabledState":
            if let modeId: Int = method.argument(key: "modeId"),
               let enabled: Bool = method.argument(key: "enabled") {
                setModeEnabled(modeId, enabled: enabled)
                result.success()
            } else {
                result.reject(code: "-1", message: "Invalid modeId or enabled argument", details: nil)
            }

        case "updateBarcodeBatchMode":
            if let modeJson: String = method.arguments() {
                updateModeFromJson(modeJson: modeJson, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid mode JSON argument", details: nil)
            }

        case "applyBarcodeBatchModeSettings":
            if let modeId: Int = method.argument(key: "modeId"),
               let modeSettingsJson: String = method.argument(key: "modeSettingsJson") {
                applyModeSettings(modeId, modeSettingsJson: modeSettingsJson, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid modeId or modeSettingsJson argument", details: nil)
            }

        case "updateBarcodeBatchBasicOverlay":
            if let dataCaptureViewId: Int = method.argument(key: "dataCaptureViewId"),
               let overlayJson: String = method.argument(key: "overlayJson") {
                updateBasicOverlay(dataCaptureViewId, overlayJson: overlayJson, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid overlay JSON argument", details: nil)
            }

        case "updateBarcodeBatchAdvancedOverlay":
            if let dataCaptureViewId: Int = method.argument(key: "dataCaptureViewId"),
               let overlayJson: String = method.argument(key: "overlayJson") {
                updateAdvancedOverlay(dataCaptureViewId, overlayJson: overlayJson, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid overlay JSON argument", details: nil)
            }

        default:
            return false
        }

        return true
    }
}

extension BarcodeBatchModule: DeserializationLifeCycleObserver {
    public func dataCaptureContext(addMode modeJson: String) throws {
        guard let dcContext = captureContext.context else {
            return
        }

        do {
            let creationParams = try BarcodeBatchModeCreationData.fromJson(modeJson)

            if creationParams.modeType != "barcodeTracking" {
                return
            }

            let batchMode = try FrameworksBarcodeBatchMode.create(
                emitter: emitter,
                captureContext: DefaultFrameworksCaptureContext.shared,
                creationData: creationParams,
                dataCaptureContext: dcContext,
                cachedBatchSession: self.cachedBatchSession)

            addModeToCache(modeId: creationParams.modeId, mode: batchMode)
            for action in getPostModeCreationActions(creationParams.modeId) {
                action()
            }
            let parentId = batchMode.parentId ?? -1
            for action in getPostModeCreationActionsByParent(parentId) {
                action()
            }
        } catch {
            print(error)
        }
    }

    public func dataCaptureContext(removeMode modeJson: String) {
        let json = JSONValue(string: modeJson)

        if json.string(forKey: "type") != "barcodeTracking" {
            return
        }

        let modeId = json.integer(forKey: "modeId", default: -1)

        guard let mode = getModeFromCache(modeId) else {
            return
        }
        mode.dispose()
        _ = removeModeFromCache(modeId)
        clearPostModeCreationActions(modeId)
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
        let creationParams = BarcodeBatchOverlayCreationData.fromJson(overlayJson)
        if !creationParams.isBasic && !creationParams.isAdvanced {
            return
        }

        let parentId = view.parentId ?? -1
        
        var mode: FrameworksBarcodeBatchMode?
        
        if parentId != -1 {
            mode = getModeFromCacheByParent(parentId) as? FrameworksBarcodeBatchMode
        } else {
            mode = getModeFromCache(creationParams.modeId)
        }
        
        if mode == nil {
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
                if creationParams.isAdvanced {
                    let overlay = try barcodeBatchDeserializer.advancedOverlay(
                        fromJSONString: creationParams.overlayJsonString,
                        withMode: mode!.mode
                    )
                    if creationParams.hasListeners {
                        overlay.delegate = barcodeBatchAdvancedOverlayListener
                    }
                    view.addOverlay(overlay)
                } else {
                    let overlay = try barcodeBatchDeserializer.basicOverlay(
                        fromJSONString: overlayJson,
                        withMode: mode!.mode
                    )
                    if creationParams.hasListeners {
                        overlay.delegate = barcodeBatchBasicOverlayListener
                    }
                    view.addOverlay(overlay)
                }
            }
        } catch {
            Log.error(error)
        }
    }
    
    public func dataCaptureView(removedOverlay overlay: any DataCaptureOverlay) {
        (overlay as? BarcodeBatchBasicOverlay)?.delegate = nil
        (overlay as? BarcodeBatchAdvancedOverlay)?.delegate = nil
    }
}

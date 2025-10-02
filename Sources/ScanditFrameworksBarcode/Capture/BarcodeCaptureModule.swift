/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture
import ScanditFrameworksCore


open class BarcodeCaptureModule: BasicFrameworkModule<FrameworksBarcodeCaptureMode> {

    private enum FunctionNames {
        static let finishDidScan = "finishDidScan"
        static let finishDidUpdateSession = "finishDidUpdateSession"
        static let addBarcodeCaptureListener = "addBarcodeCaptureListener"
        static let removeBarcodeCaptureListener = "removeBarcodeCaptureListener"
        static let resetBarcodeCaptureSession = "resetBarcodeCaptureSession"
        static let getLastFrameData = "getLastFrameData"
        static let getBarcodeCaptureDefaults = "getBarcodeCaptureDefaults"
        static let setModeEnabledState = "setModeEnabledState"
        static let updateBarcodeCaptureMode = "updateBarcodeCaptureMode"
        static let applyBarcodeCaptureModeSettings = "applyBarcodeCaptureModeSettings"
        static let updateBarcodeCaptureOverlay = "updateBarcodeCaptureOverlay"
        static let updateFeedback = "updateFeedback"
    }

    private let barcodeCaptureDeserializer: BarcodeCaptureDeserializer
    private let emitter: Emitter
    private let captureContext = DefaultFrameworksCaptureContext.shared
    private let captureViewHandler = DataCaptureViewHandler.shared

    private let cachedCaptureSession: AtomicValue<FrameworksBarcodeCaptureSession?> = AtomicValue(nil)

    public init(emitter: Emitter) {
        self.emitter = emitter
        self.barcodeCaptureDeserializer = BarcodeCaptureDeserializer()
    }

    // MARK: - FrameworkModule API

    public override func didStart() {
        DeserializationLifeCycleDispatcher.shared.attach(observer: self)
    }

    public override func didStop() {
        DeserializationLifeCycleDispatcher.shared.detach(observer: self)
    }

    // MARK: - Module API exposed to the platform native modules

    public let defaults: DefaultsEncodable = BarcodeCaptureDefaults.shared

    public func addListener(modeId: Int) {
        guard let mode = getModeFromCache(modeId) else {
            addPostModeCreationAction(modeId, action: {
                self.addListener(modeId: modeId)
            })
            return
        }
        mode.addListener()
    }

    public func removeListener(modeId: Int) {
        if let mode = getModeFromCache(modeId) {
            mode.removeListener()
        }
    }

    public func finishDidScan(modeId: Int, enabled: Bool) {
        if let mode = getModeFromCache(modeId) {
            mode.finishDidScan(enabled: enabled)
        }
    }

    public func finishDidUpdateSession(modeId: Int, enabled: Bool) {
        if let mode = getModeFromCache(modeId) {
            mode.finishDidUpdateSession(enabled: enabled)
        }
    }

    public func resetSession() {
        if let session = self.cachedCaptureSession.value {
            session.captureSession?.reset()
        }
    }

    public func setModeEnabled(modeId: Int, enabled: Bool) {
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

    public func applyModeSettings(modeId: Int, modeSettingsJson: String, result: FrameworksResult) {
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

    public func updateOverlay(_ viewId: Int, overlayJson: String, result: FrameworksResult) {
        let block = { [weak self] in
            guard let self = self else {
                result.reject(error: ScanditFrameworksCoreError.nilSelf)
                return
            }

            guard let dcView = self.captureViewHandler.getView(viewId),
               let overlay: BarcodeCaptureOverlay = dcView.findFirstOfType() else {
                result.success()
                return
            }

            do {
                try self.barcodeCaptureDeserializer.update(overlay, fromJSONString: overlayJson)
                result.success()
            } catch {
                result.reject(error: error)
            }
        }
        dispatchMain(block)
    }

    public func updateFeedback(modeId: Int, feedbackJson: String, result: FrameworksResult) {
        guard let mode = getModeFromCache(modeId) else {
            result.success()
            return
        }
        do {
            try mode.updateFeedback(feedbackJson: feedbackJson)
            result.success()
        } catch {
            result.reject(error: error)
        }
    }

    public func getLastFrameDataBytes(frameId: String, result: FrameworksResult) {
        LastFrameData.shared.getLastFrameDataBytes(frameId: frameId) {
            result.success(result: $0)
        }
    }

    // MARK: - Execute Method
    public func execute(method: FrameworksMethodCall, result: FrameworksResult) -> Bool {
        switch method.method {
        case FunctionNames.getBarcodeCaptureDefaults:
            let defaultsDict = defaults.toEncodable()
            if let jsonString = defaultsDict.encodeToJSONString() {
                result.success(result: jsonString)
            } else {
                result.reject(code: "-1", message: "Failed to encode defaults to JSON", details: nil)
            }

        case FunctionNames.finishDidScan:
            if let enabled: Bool = method.argument(key: "enabled"), let modeId: Int = method.argument(key: "modeId") {
                finishDidScan(modeId: modeId, enabled: enabled)
                result.success()
            } else {
                result.reject(code: "-1", message: "Invalid enabled or modeId argument", details: nil)
            }

        case FunctionNames.finishDidUpdateSession:
            if let enabled: Bool = method.argument(key: "enabled"), let modeId: Int = method.argument(key: "modeId") {
                finishDidUpdateSession(modeId: modeId, enabled: enabled)
                result.success()
            } else {
                result.reject(code: "-1", message: "Invalid enabled or modeId argument", details: nil)
            }

        case FunctionNames.addBarcodeCaptureListener:
            if let modeId: Int = method.argument(key: "modeId") {
                addListener(modeId: modeId)
                result.success()
            } else {
                result.reject(code: "-1", message: "Invalid modeId argument", details: nil)
            }

        case FunctionNames.removeBarcodeCaptureListener:
            if let modeId: Int = method.argument(key: "modeId") {
                removeListener(modeId: modeId)
                result.success()
            } else {
                result.reject(code: "-1", message: "Invalid modeId argument", details: nil)
            }

        case FunctionNames.resetBarcodeCaptureSession:
            resetSession()
            result.success()

        case FunctionNames.getLastFrameData:
            if let frameId: String = method.arguments() {
                getLastFrameDataBytes(frameId: frameId, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid frameId argument", details: nil)
            }

        case FunctionNames.setModeEnabledState:
            if let modeId: Int = method.argument(key: "modeId"),
               let enabled: Bool = method.argument(key: "enabled") {
                setModeEnabled(modeId: modeId, enabled: enabled)
                result.success()
            } else {
                result.reject(code: "-1", message: "Invalid modeId or enabled argument", details: nil)
            }

        case FunctionNames.updateBarcodeCaptureMode:
            if let modeJson: String = method.arguments() {
                updateModeFromJson(modeJson: modeJson, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid mode JSON argument", details: nil)
            }

        case FunctionNames.applyBarcodeCaptureModeSettings:
            if let modeId: Int = method.argument(key: "modeId"),
               let modeSettingsJson: String = method.argument(key: "modeSettingsJson") {
                applyModeSettings(modeId: modeId, modeSettingsJson: modeSettingsJson, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid modeId or modeSettingsJson argument", details: nil)
            }

        case FunctionNames.updateBarcodeCaptureOverlay:
            if let viewId: Int = method.argument(key: "viewId"),
               let overlayJson: String = method.argument(key: "overlayJson") {
                updateOverlay(viewId, overlayJson: overlayJson, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid viewId or overlayJson argument", details: nil)
            }

        case FunctionNames.updateFeedback:
            if let modeId: Int = method.argument(key: "modeId"),
               let feedbackJson: String = method.argument(key: "feedbackJson") {
                updateFeedback(modeId: modeId, feedbackJson: feedbackJson, result: result)
            } else {
                result.reject(code: "-1", message: "Invalid modeId or feedbackJson argument", details: nil)
            }

        default:
            return false
        }

        return true
    }
}

extension BarcodeCaptureModule: DeserializationLifeCycleObserver {
    public func dataCaptureContext(addMode modeJson: String) throws {
        guard let dcContext = captureContext.context else {
            return
        }

        do {
            let creationParams = try BarcodeCaptureModeCreationData.fromJson(modeJson)

            if creationParams.modeType != "barcodeCapture" {
                return
            }

            let captureMode = try FrameworksBarcodeCaptureMode.create(
                emitter: emitter,
                captureContext: DefaultFrameworksCaptureContext.shared,
                creationData: creationParams,
                dataCaptureContext: dcContext,
                cachedCaptureSession: self.cachedCaptureSession)

            addModeToCache(modeId: creationParams.modeId, mode: captureMode)
            for action in getPostModeCreationActions(creationParams.modeId) {
                action()
            }
        } catch {
            print(error)
        }
    }

    public func dataCaptureContext(removeMode modeJson: String) {
        let json = JSONValue(string: modeJson)

        if json.string(forKey: "type") != "barcodeCapture" {
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
        let creationParams = BarcodeCaptureOverlayCreationData.fromJson(overlayJson)
        if !creationParams.isBasic {
            return
        }

        let parentId = view.parentId ?? -1

        var mode: FrameworksBarcodeCaptureMode?

        if parentId != -1 {
            mode = getModeFromCacheByParent(parentId) as? FrameworksBarcodeCaptureMode
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
                let overlay = try barcodeCaptureDeserializer.overlay(
                    fromJSONString: overlayJson,
                    withMode: mode!.mode
                )
                view.addOverlay(overlay)
            }
        } catch {
            Log.error(error)
        }
    }
}

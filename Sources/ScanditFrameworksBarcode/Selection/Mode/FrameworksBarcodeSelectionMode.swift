/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2025- Scandit AG. All rights reserved.
 */

import ScanditBarcodeCapture
import ScanditFrameworksCore

public class FrameworksBarcodeSelectionMode: FrameworksBaseMode {
    private let listener: FrameworksBarcodeSelectionListener
    private let captureContext: DefaultFrameworksCaptureContext
    private let deserializer: BarcodeSelectionDeserializer

    private var _modeId: Int = -1
    private var _parentId: Int? = nil

    public var modeId: Int {
        return _modeId
    }

    public var parentId: Int? {
        return _parentId
    }

    public private(set) var mode: BarcodeSelection!

    public var isEnabled: Bool {
        get {
            return mode.isEnabled
        }
        set {
            mode.isEnabled = newValue
        }
    }

    public init(
        listener: FrameworksBarcodeSelectionListener,
        captureContext: DefaultFrameworksCaptureContext,
        deserializer: BarcodeSelectionDeserializer
    ) {
        self.listener = listener
        self.captureContext = captureContext
        self.deserializer = deserializer
    }

    private func deserializeMode(
        dataCaptureContext: DataCaptureContext,
        creationData: BarcodeSelectionModeCreationData
    ) throws {
        mode = try deserializer.mode(fromJSONString: creationData.modeJson, with: dataCaptureContext)
        _modeId = creationData.modeId
        _parentId = creationData.parentId

        captureContext.addMode(mode: mode)

        if creationData.hasListener {
            mode.addListener(listener)
        }

        mode.isEnabled = creationData.isEnabled
    }

    public func resetSelection() {
        mode.reset()
    }

    public func dispose() {
        mode.removeListener(listener)
        listener.reset()
        captureContext.removeMode(mode: mode)
    }

    public func addListener() {
        mode.addListener(listener)
    }

    public func removeListener() {
        mode.removeListener(listener)
    }

    public func finishDidUpdateSession(enabled: Bool) {
        listener.finishDidUpdate(enabled: enabled)
    }

    public func applySettings(modeSettingsJson: String) throws {
        let settings = try deserializer.settings(fromJSONString: modeSettingsJson)
        mode.apply(settings)
    }

    public func updateModeFromJson(modeJson: String) throws {
        try deserializer.updateMode(mode, fromJSONString: modeJson)
    }

    public func updateFeedback(feedback: BarcodeSelectionFeedback) {
        mode.feedback = feedback
    }

    public func cancelPendingEvents() {
        listener.reset()
    }

    public func unfreezeCamera() {
        mode.unfreezeCamera()
    }

    public func selectAimedBarcode() {
        mode.selectAimedBarcode()
    }

    public func unselectBarcodesFromJsonString(barcodesJson: String) {
        mode.unselectBarcodes(fromJsonString: barcodesJson)
    }

    public func setSelectBarcodeEnabledFromJsonString(barcodesJson: String, enabled: Bool) {
        mode.setSelectBarcodeFromJsonString(barcodesJson, enabled: enabled)
    }

    public func getSelectedBarcodeCount(selectionIdentifier: String) -> Int {
        return listener.getBarcodeCount(selectionIdentifier: selectionIdentifier)
    }

    public func resetSession(frameSequenceId: Int?) {
        listener.resetSession(frameSequenceId: frameSequenceId)
    }

    public func finishDidSelect(enabled: Bool) {
        listener.finishDidSelect(enabled: enabled)
    }

    public func increaseCountForBarcodesFromJsonString(barcodesJson: String) {
        mode.increaseCountForBarcodes(fromJsonString: barcodesJson)
    }

    public func setModeEnabled(enabled: Bool) {
        mode.isEnabled = enabled
    }

    // MARK: - Factory Method

    public static func create(
        emitter: Emitter,
        captureContext: DefaultFrameworksCaptureContext,
        creationData: BarcodeSelectionModeCreationData,
        dataCaptureContext: DataCaptureContext,
        deserializer: BarcodeSelectionDeserializer
    ) throws -> FrameworksBarcodeSelectionMode {
        let listener = FrameworksBarcodeSelectionListener(emitter: emitter, modeId: creationData.modeId)
        let mode = FrameworksBarcodeSelectionMode(
            listener: listener,
            captureContext: captureContext,
            deserializer: deserializer
        )

        try mode.deserializeMode(dataCaptureContext: dataCaptureContext, creationData: creationData)
        return mode
    }
}
